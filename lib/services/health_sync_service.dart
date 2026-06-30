import 'dart:io';

import 'package:health/health.dart';
import 'package:intl/intl.dart';

import '../firestore_service.dart';

/// Result of a health sync attempt, surfaced to the UI as a SnackBar.
class HealthSyncResult {
  final bool success;
  final String message;
  final int nightsImported;

  const HealthSyncResult({
    required this.success,
    required this.message,
    this.nightsImported = 0,
  });
}

/// Reads sleep data from Apple Health (HealthKit) / Android Health Connect
/// via the `health` package and imports it into Firestore `sleep_logs`
/// through [FirestoreService.saveSleepLogFromHealth].
class HealthSyncService {
  final Health _health = Health();
  final FirestoreService _firestoreService = FirestoreService();
  bool _configured = false;

  // "Asleep but unknown stage" (SLEEP_ASLEEP) is folded into the light-sleep
  // bucket, matching how _buildSleepLogData already derives lightSleep as a
  // remainder when explicit stage data isn't available.
  static const List<HealthDataType> _iosSleepTypes = [
    HealthDataType.SLEEP_IN_BED,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_REM,
  ];

  static const List<HealthDataType> _androidSleepTypes = [
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_AWAKE_IN_BED,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_REM,
  ];

  // Types that represent "asleep" time (any stage, including unknown).
  static const Set<HealthDataType> _asleepTypes = {
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_REM,
  };

  // Types that represent being awake (either in bed or otherwise) during the
  // tracked session.
  static const Set<HealthDataType> _awakeTypes = {
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_AWAKE_IN_BED,
  };

  List<HealthDataType> get _sleepTypes =>
      Platform.isIOS ? _iosSleepTypes : _androidSleepTypes;

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  /// Requests authorization for sleep data and performs a one-time
  /// historical backfill (default 30 days, matching the existing 30-day
  /// rolling-average convention elsewhere in this codebase).
  Future<HealthSyncResult> requestAuthorizationAndInitialSync({
    int lookbackDays = 30,
  }) async {
    try {
      await _ensureConfigured();

      if (Platform.isAndroid && !await _health.isHealthConnectAvailable()) {
        return const HealthSyncResult(
          success: false,
          message:
              'Health Connect isn\'t installed on this device. Install it from the Play Store to sync sleep data.',
        );
      }

      final granted = await _health.requestAuthorization(_sleepTypes);
      if (!granted) {
        return const HealthSyncResult(
          success: false,
          message: 'Health permission wasn\'t granted.',
        );
      }

      return syncRecentDays(days: lookbackDays);
    } catch (e) {
      return HealthSyncResult(success: false, message: 'Health sync failed: $e');
    }
  }

  /// Fetches sleep data from the last [days] days, groups it into nightly
  /// sessions, and imports each night via [FirestoreService.saveSleepLogFromHealth].
  Future<HealthSyncResult> syncRecentDays({int days = 2}) async {
    try {
      await _ensureConfigured();

      final now = DateTime.now();
      final start = now.subtract(Duration(days: days));

      final points = await _health.getHealthDataFromTypes(
        types: _sleepTypes,
        startTime: start,
        endTime: now,
      );

      if (points.isEmpty) {
        return const HealthSyncResult(
          success: true,
          message: 'No new sleep data found.',
        );
      }

      final nights = _groupIntoNights(points);
      for (final night in nights) {
        await _firestoreService.saveSleepLogFromHealth(
          totalDuration: night.totalDurationStr,
          deepSleep: night.deepStr,
          remSleep: night.remStr,
          awakeTime: night.awakeStr,
          timeInBed: night.timeInBedStr,
          timeAsleep: night.timeAsleepStr,
          timeAwake: night.timeAwakeStr,
          quality: 'Health Sync',
          date: night.date,
        );
      }

      return HealthSyncResult(
        success: true,
        message: 'Synced ${nights.length} night${nights.length == 1 ? '' : 's'} of sleep data.',
        nightsImported: nights.length,
      );
    } catch (e) {
      return HealthSyncResult(success: false, message: 'Health sync failed: $e');
    }
  }

  /// Groups raw sleep [HealthDataPoint]s into nightly sessions. Points more
  /// than [gapMinutes] apart are treated as belonging to different nights.
  /// Sessions shorter than [minSessionMinutes] (likely naps/noise) are
  /// dropped.
  List<_NightSummary> _groupIntoNights(
    List<HealthDataPoint> points, {
    int gapMinutes = 90,
    int minSessionMinutes = 60,
  }) {
    final sorted = [...points]..sort((a, b) => a.dateFrom.compareTo(b.dateFrom));

    final clusters = <List<HealthDataPoint>>[];
    DateTime? clusterEnd;
    for (final p in sorted) {
      if (clusters.isEmpty || clusterEnd == null ||
          p.dateFrom.difference(clusterEnd).inMinutes > gapMinutes) {
        clusters.add([p]);
      } else {
        clusters.last.add(p);
      }
      if (clusterEnd == null || p.dateTo.isAfter(clusterEnd)) {
        clusterEnd = p.dateTo;
      }
    }

    final nights = <_NightSummary>[];
    for (final cluster in clusters) {
      final summary = _summarizeCluster(cluster);
      if (summary == null) continue;
      if (summary.totalMinutes < minSessionMinutes) continue;
      nights.add(summary);
    }
    return nights;
  }

  _NightSummary? _summarizeCluster(List<HealthDataPoint> cluster) {
    int deepMin = 0;
    int remMin = 0;
    int lightMin = 0; // explicit SLEEP_LIGHT + unspecified SLEEP_ASLEEP
    int awakeMin = 0;

    DateTime? timeInBed;
    DateTime? timeAsleep;
    DateTime? timeAwake;

    for (final p in cluster) {
      final minutes = p.dateTo.difference(p.dateFrom).inMinutes;
      if (minutes <= 0) continue;

      if (timeInBed == null || p.dateFrom.isBefore(timeInBed)) {
        timeInBed = p.dateFrom;
      }
      if (timeAwake == null || p.dateTo.isAfter(timeAwake)) {
        timeAwake = p.dateTo;
      }

      switch (p.type) {
        case HealthDataType.SLEEP_DEEP:
          deepMin += minutes;
          break;
        case HealthDataType.SLEEP_REM:
          remMin += minutes;
          break;
        case HealthDataType.SLEEP_LIGHT:
        case HealthDataType.SLEEP_ASLEEP:
          lightMin += minutes;
          break;
        case HealthDataType.SLEEP_AWAKE:
        case HealthDataType.SLEEP_AWAKE_IN_BED:
          awakeMin += minutes;
          break;
        default:
          break;
      }

      if (_asleepTypes.contains(p.type) &&
          (timeAsleep == null || p.dateFrom.isBefore(timeAsleep))) {
        timeAsleep = p.dateFrom;
      }
    }

    if (timeInBed == null || timeAwake == null) return null;
    // Fall back to the in-bed time if no asleep-stage point was found at all
    // (shouldn't normally happen given _asleepTypes covers every counted type).
    timeAsleep ??= timeInBed;

    // Exclude awake time that happened before sleep onset (that's latency,
    // not an awakening) so it isn't double counted.
    int awakeAfterSleepOnsetMin = 0;
    for (final p in cluster) {
      if (!_awakeTypes.contains(p.type)) continue;
      if (!p.dateFrom.isBefore(timeAsleep)) {
        awakeAfterSleepOnsetMin += p.dateTo.difference(p.dateFrom).inMinutes;
      }
    }
    awakeMin = awakeAfterSleepOnsetMin;

    final totalMin = deepMin + remMin + lightMin + awakeMin;
    if (totalMin <= 0) return null;

    // A night "belongs to" the date it was woken up on, unless that wake-up
    // happened after noon (unusual), in which case fall back to the bedtime's
    // date.
    final date = timeAwake.hour < 12
        ? DateTime(timeAwake.year, timeAwake.month, timeAwake.day)
        : DateTime(timeInBed.year, timeInBed.month, timeInBed.day);

    return _NightSummary(
      date: date,
      totalMinutes: totalMin,
      deepMinutes: deepMin,
      remMinutes: remMin,
      awakeMinutes: awakeMin,
      timeInBed: timeInBed,
      timeAsleep: timeAsleep,
      timeAwake: timeAwake,
    );
  }
}

String _durationStr(int minutes) => '${minutes ~/ 60}h${minutes % 60}m';

String _clockStr(DateTime dt) => DateFormat.jm().format(dt);

class _NightSummary {
  final DateTime date;
  final int totalMinutes;
  final int deepMinutes;
  final int remMinutes;
  final int awakeMinutes;
  final DateTime timeInBed;
  final DateTime timeAsleep;
  final DateTime timeAwake;

  _NightSummary({
    required this.date,
    required this.totalMinutes,
    required this.deepMinutes,
    required this.remMinutes,
    required this.awakeMinutes,
    required this.timeInBed,
    required this.timeAsleep,
    required this.timeAwake,
  });

  String get totalDurationStr => _durationStr(totalMinutes);
  String get deepStr => _durationStr(deepMinutes);
  String get remStr => _durationStr(remMinutes);
  String get awakeStr => _durationStr(awakeMinutes);
  String get timeInBedStr => _clockStr(timeInBed);
  String get timeAsleepStr => _clockStr(timeAsleep);
  String get timeAwakeStr => _clockStr(timeAwake);
}
