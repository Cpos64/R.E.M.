import 'dart:math';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'firestore_service.dart';
import 'view_dream_screen.dart';

import '../widgets/multi_dream_entry_modal.dart';
import 'screens/settings_screen.dart';
import 'services/health_sync_service.dart';
import 'theme/app_transitions.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  final Function(bool) toggleTheme;
  final bool isDarkTheme;

  const HomeScreen({
    required this.toggleTheme,
    required this.isDarkTheme,
    super.key,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _reminderEnabled = false;
  bool _dreamPromptEnabled = true;
  final FirestoreService _firestoreService = FirestoreService();
  final HealthSyncService _healthSyncService = HealthSyncService();
  StreamSubscription? _sleepSub;
  StreamSubscription? _dreamSub;

  Map<String, dynamic>? _lastSleep;
  List<QueryDocumentSnapshot> _recentDreams = [];
  double _weekAvgMinutes = 0;
  int _weekDreamCount = 0;
  bool _loadingData = true;

  @override
  void initState() {
    super.initState();
    _loadDreamPromptSetting().then((_) {
      // Trigger the daily dream prompt as soon as the home screen appears:
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybeShowDreamQuestion();
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeSyncHealthData();
    });
    _fetchHomeData();
    _startListeners();
  }

  /// Silently syncs Health/Health Connect sleep data at most once per day,
  /// mirroring _maybeShowDreamQuestion's once-per-day pattern. Fire-and-forget:
  /// the existing _sleepSub stream listener already refreshes the UI once a
  /// new sleep_logs doc lands.
  Future<void> _maybeSyncHealthData() async {
    final prefs = await SharedPreferences.getInstance();
    final healthSyncEnabled = prefs.getBool('healthSyncEnabled') ?? false;
    if (!healthSyncEnabled) return;

    final lastSync = prefs.getString('lastHealthSyncDate');
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (lastSync == today) return;

    await _healthSyncService.syncRecentDays(days: 2);
    await prefs.setString('lastHealthSyncDate', today);
  }

  Future<void> _loadDreamPromptSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dreamPromptEnabled = prefs.getBool('dreamPromptEnabled') ?? true;
    });
  }

  Future<void> _maybeShowDreamQuestion() async {
    if (!_dreamPromptEnabled) return;
    final prefs = await SharedPreferences.getInstance();
    final lastPrompt = prefs.getString('lastDreamPromptDate');
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (lastPrompt != today) {
      _showDreamQuestionDialog();
    }
  }

  Future<void> _setPromptDate() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setString('lastDreamPromptDate', today);
  }

  void _showDreamQuestionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Did you dream last night?'),
        actions: [
          TextButton(
            onPressed: () async {
              await _setPromptDate();
              Navigator.of(context).pop();
            },
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _setPromptDate();
              Navigator.of(context).pop();
              await _openMultiDreamModal();
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  Future<void> _openMultiDreamModal() async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Padding(
        // make room for the keyboard
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          // cover 90% of screen height
          height: MediaQuery.of(ctx).size.height * 0.9,
          decoration: BoxDecoration(
            color: Theme.of(ctx).canvasColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: const MultiDreamEntryModal(),
        ),
      );
    },
  );
  await _fetchHomeData();
  }

  Future<void> _fetchHomeData() async {
    setState(() => _loadingData = true);
    try {
      final sleep = await _firestoreService.getMostRecentSleepLog();
      final dreams = await _firestoreService.getRecentDreams();
      final stats = await _firestoreService.getCurrentWeekStats();

      setState(() {
        _lastSleep = sleep;
        _recentDreams = dreams;
        _weekAvgMinutes = (stats['avgMinutes'] as num?)?.toDouble() ?? 0;
        _weekDreamCount = stats['dreamCount'] as int? ?? 0;
        _loadingData = false;
      });
    } catch (e) {
      setState(() => _loadingData = false);
    }
  }

  void _startListeners() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _sleepSub?.cancel();
    _dreamSub?.cancel();

    _sleepSub = FirebaseFirestore.instance
        .collection('sleep_logs')
        .where('userId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((_) => _fetchHomeData(), onError: (_) {
          setState(() => _loadingData = false);
        });

    _dreamSub = FirebaseFirestore.instance
        .collection('dreams')
        .where('userId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((_) => _fetchHomeData(), onError: (_) {
          setState(() => _loadingData = false);
        });
  }

  Future<void> _navigateAndRefresh(String route,
      {Map<String, dynamic>? args}) async {
    await Navigator.pushNamed(context, route, arguments: args);
    await _fetchHomeData();
  }

  String _formatMinutes(double minutes) {
    if (minutes <= 0) return '---';
    final min = minutes.round();
    final h = min ~/ 60;
    final m = min % 60;
    return '${h}h${m}m';
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await _auth.signOut();
    await prefs.remove('email');
    await prefs.remove('password');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logged out successfully')),
    );
    // Let auth state changes propagate
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    _sleepSub?.cancel();
    _dreamSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // A handful of sleep-related quotes
  const quotes = [
    "“Early to bed and early to rise makes a person healthy, wealthy, and wise.” – Benjamin Franklin",
    "“A good laugh and a long sleep are the best cures in the doctor's book.” – Irish Proverb",
    "“Sleep is the golden chain that binds health and our bodies together.”",
    "“Sleep is the best meditation.” – Dalai Lama",
    "“Let her sleep, for when she wakes, she will move mountains.” – Napoleon Bonaparte",
    "“Your future depends on your dreams, so go to sleep.” – Mesut Barazany",
    "“Man should forget his anger before he sleeps.” – Mahatma Gandhi",
    "“A ruffled mind makes a restless pillow.” – Charlotte Brontë",
    "“There is a time for many words, and there is also a time for sleep.” – Homer",
    "“A well-spent day brings happy sleep.” – Leonardo da Vinci",
    "“Sleep is the best cure for waking troubles.” – Miguel de Cervantes",
    "“Having peace, happiness, and healthiness is my definition of beauty. And you can’t have any of that without sleep.” – Beyonce",
    "“The nicest thing for me is sleep. Then at least I can dream.” – Marilyn Monroe",
    "“Sleep is the best time for me to think about my life and what I want to do.” – Taylor Swift",
    "“We are such stuff as dreams are made on; and our little life is rounded with a sleep.” – William Shakespeare",
    "“Finish each day before you begin the next, and interpose a solid wall of sleep between the two.” – Ralph Waldo Emerson",
    "“Sleep might be the most important aspect of building a great business, and having a high-performing body.” – Lewis Howes",
    "“Many things – such as loving, going to sleep, or behaving unaffectedly – are done worst when we try hardest to do them.” – C.S. Lewis",
    "“No day is so bad it can’t be fixed with a nap.” – Carrie Snow",
    "“It is a common experience that a problem difficult at night is resolved in the morning after the committee of sleep has worked on it.” – John Steinbeck",
    "“There is more refreshment and stimulation in a nap, even of the briefest, than in all the alcohol ever distilled.” – Edward Lucas",
    "“The way to a more productive, more inspired, more joyful life is getting enough sleep.” – Arianna Huffington",
      ];

    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day;
    final rng = Random(seed);
    final quoteOfTheDay = quotes[rng.nextInt(quotes.length)];

    final dateString = DateFormat('EEEE, MMM d').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(dateString),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              AppPageRoute(
                builder: (_) => SettingsScreen(
                  isDarkTheme: widget.isDarkTheme,
                  toggleTheme: widget.toggleTheme,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ─── Sleep Summary ───
            Card(
              child: _loadingData
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _lastSleep == null
                      ? const ListTile(
                          leading: Icon(Icons.self_improvement),
                          title: Text('Waiting for Sleep Data'),
                        )
                      : ListTile(
                          leading: const Icon(Icons.bedtime),
                          title: Text('${_lastSleep!['totalDuration']} · ${_lastSleep!['quality'] ?? ''}'),
                          subtitle: Text('${_lastSleep!['timeAsleep'] ?? ''}–${_lastSleep!['timeAwake'] ?? ''}'),
                        ),
            ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
            const SizedBox(height: 16),

            // ─── Quick-Add Buttons ───
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () =>
                      _navigateAndRefresh('/sleep_logs', args: {'add': true}),
                  child:
                      const Text('🛏️\nLog Sleep', textAlign: TextAlign.center),
                ),
                ElevatedButton(
                  onPressed: () =>
                      _navigateAndRefresh('/dreams', args: {'add': true}),
                  child:
                      const Text('💭\nRecord Dream', textAlign: TextAlign.center),
                ),
              ],
            ).animate().fadeIn(delay: 80.ms, duration: 350.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
            const SizedBox(height: 16),

            // ─── Recent Dreams ───
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Recent Dreams:'),
                    const SizedBox(height: 8),
                    if (_recentDreams.isEmpty)
                      const Text('No dreams yet.')
                    else
                      ..._recentDreams.asMap().entries.map((entry) {
                        final index = entry.key;
                        final doc = entry.value;
                        final data = doc.data() as Map<String, dynamic>;
                        final title = data['title'] ?? '';
                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              AppPageRoute(
                                builder: (_) => ViewDreamScreen(
                                  docId: doc.id,
                                  title: title,
                                  description: data['description'] ?? '',
                                  timestamp:
                                      (data['timestamp'] as Timestamp).toDate(),
                                  tags: data.containsKey('genres')
                                      ? (data['genres'] as List).cast<String>()
                                      : [(data['genre'] as String?) ?? 'Other'],
                                  sentimentScore:
                                      (data['sentimentScore'] as num?)?.toDouble() ??
                                          0.0,
                                  recallRating:
                                      (data['recallRating'] as num?)?.toInt() ?? 0,
                                ),
                              ),
                            );
                          },
                          child: Text('▶︎ "$title"'),
                        ).animate().fadeIn(
                              delay: (100 + index * 60).ms,
                              duration: 300.ms,
                            ).slideX(begin: 0.05, end: 0, curve: Curves.easeOutCubic);
                      }).toList(),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _navigateAndRefresh('/dreams'),
                        child: const Text('See All →'),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 140.ms, duration: 350.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
            const SizedBox(height: 16),

            // ─── Quote of the Day ───
            Card(
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  quoteOfTheDay,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 350.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
            const SizedBox(height: 16),

            // ─── Weekly Stats ───
            Card(
              child: ListTile(
                title: Text(
                    'Weekly Stats:  Avg: ${_formatMinutes(_weekAvgMinutes)}   Dreams: $_weekDreamCount'),
                trailing: TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/stats'),
                  child: const Text('View Full Stats →'),
                ),
              ),
            ).animate().fadeIn(delay: 260.ms, duration: 350.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
          ],
        ),
      ),
    );
  }
}