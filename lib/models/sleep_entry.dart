/// A single night’s sleep record
class SleepEntry {
  /// The date of the sleep (e.g. the day you woke up)
  final DateTime date;
  /// Your sleep score for that night
  final double sleepScore;

  SleepEntry({
    required this.date,
    required this.sleepScore,
  });
}
