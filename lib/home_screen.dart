import 'dart:math';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/multi_dream_entry_modal.dart';

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

  @override
  void initState() {
    super.initState();
    // Trigger the daily dream prompt as soon as the home screen appears:
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowDreamQuestion(); //<- commented out for testing
      // _showDreamQuestionDialog(); // <-- delete this after testing
    });
  }

  Future<void> _maybeShowDreamQuestion() async {
    final prefs = await SharedPreferences.getInstance();
    final lastPrompt = prefs.getString('lastDreamPromptDate');
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (lastPrompt != today) {
      // Mark that we've asked today
      await prefs.setString('lastDreamPromptDate', today);
      _showDreamQuestionDialog();
    }
  }

  void _showDreamQuestionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Did you dream last night?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _openMultiDreamModal();
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

void _openMultiDreamModal() {
  showModalBottomSheet(
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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.settings),
          tooltip: 'Settings',
          onPressed: () => Navigator.pushNamed(context, '/settings'),
        ),
        title: const Text('R.E.M. Home'),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkTheme ? Icons.nights_stay : Icons.wb_sunny),
            tooltip: 'Toggle theme',
            onPressed: () => widget.toggleTheme(!widget.isDarkTheme),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Welcome to R.E.M!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // ─── Quick-Add Buttons ───
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/sleep_logs'),
                  icon: const Icon(Icons.bedtime, size: 32),
                  label: const Text("Add Sleep", style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(140, 140),
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/dreams'),
                  icon: const Icon(Icons.book, size: 32),
                  label: const Text("Add Dream", style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(140, 140),
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

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
            ),
            const SizedBox(height: 32),

            // ─── Bedtime Reminder Toggle ───
            SwitchListTile(
              title: const Text("Bedtime Reminder"),
              subtitle: const Text("Notify me every night at 10:30 PM"),
              value: _reminderEnabled,
              onChanged: (v) => setState(() => _reminderEnabled = v),
              secondary: const Icon(Icons.alarm),
            ),
          ],
        ),
      ),
    );
  }
}