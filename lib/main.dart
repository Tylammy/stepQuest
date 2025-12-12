import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'battle_screen.dart';
import 'daily_quest_screen.dart';
import 'package:pedometer/pedometer.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const StepQuestApp());
}


class StepQuestApp extends StatelessWidget {
  const StepQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StepQuest',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        
        scaffoldBackgroundColor: const Color(0xFFF4F5FF),

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 2,
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
      home: const CharacterListScreen(),
    );
  }
}

/// ------------------------------------------------------------
/// WEEK 1: CHARACTER LIST SCREEN
/// ------------------------------------------------------------
/// - Reads all characters from the "characters" collection
///   in Firestore.
/// - Lets the user tap on a character to open the StepTrackerScreen
///   for that specific character (steps and XP saved per character).
class CharacterListScreen extends StatelessWidget {
  const CharacterListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Characters"),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Your party',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Expanded(
            // StreamBuilder show characters from Firestore
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('characters')
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No characters yet.\nTap the button below to create one.",
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final name = (data['name'] ?? 'Unknown') as String;
                    final charClass = (data['class'] ?? 'Unknown') as String;
                    final xp = (data['xp'] ?? 0) as int;
                    final level = (data['level'] ?? 1) as int;

                    final String initial =
                      name.isNotEmpty ? name[0].toUpperCase() : '?';

                    return Card(
                      // Card for each character
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          // Avatar with initial
                          radius: 22,
                          backgroundColor: Colors.indigo.shade100,
                          child: Text(
                            initial,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text('$charClass • Lv $level • $xp XP'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  StepTrackerScreen(characterRef: doc.reference),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CharacterCreationScreen(),
                    ),
                  );
                },
                child: const Text("Create Character"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Character Creation Screen
/// - Saves a new character document into
///   the "characters" collection in Firestore.
class CharacterCreationScreen extends StatefulWidget {
  const CharacterCreationScreen({super.key});

  @override
  State<CharacterCreationScreen> createState() =>
      _CharacterCreationScreenState();
}

class _CharacterCreationScreenState extends State<CharacterCreationScreen> {
  // Controller for the character name text field
  final TextEditingController _nameController = TextEditingController();

  // Default selected class
  String selectedClass = "Warrior";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Character"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              "Character Name",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            // Simple text field for entering the character's name.
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: "Enter name",
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              "Class",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            // Dropdown picker for selecting class
            DropdownButton<String>(
              value: selectedClass,
              onChanged: (value) {
                setState(() => selectedClass = value!);
              },
              items: const [
                DropdownMenuItem(value: "Warrior", child: Text("Warrior")),
                DropdownMenuItem(value: "Ranger", child: Text("Ranger")),
                DropdownMenuItem(value: "Mage", child: Text("Mage")),
              ],
            ),

            const SizedBox(height: 40),


            // Save Character button - writes to Firestore
            ElevatedButton(
              onPressed: () async {
                final name = _nameController.text.trim();

                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Name cannot be empty"),
                    ),
                  );
                  return;
                }

                try {
                  // Write a new document into the "characters" collection
                  await FirebaseFirestore.instance.collection('characters').add({
                    'name': name,
                    'class': selectedClass,
                    'xp': 0,
                    'steps': 0,
                    'level': 1,
                    'createdAt': FieldValue.serverTimestamp(),
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Character saved to Firestore!"),
                    ),
                  );

                  // Go back to the previous screen
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error saving character: $e"),
                    ),
                  );
                }
              },
              child: const Text("Save Character"),
            ),
          ],
        ),
      ),
    );
  }
}


// ---------------------------------
// STEP TRACKING INTEGRATION
// ---------------------------------
/// - Listens to device step sensor using the `pedometer` package.
/// - Each new step increments `steps`, `xp`, and daily step quests in Firestore.
/// - Also keeps the manual "Add 100 Steps" button as a fallback.

class StepTrackerScreen extends StatefulWidget {
  final DocumentReference<Map<String, dynamic>> characterRef;

  const StepTrackerScreen({super.key, required this.characterRef});

  @override
  State<StepTrackerScreen> createState() => _StepTrackerScreenState();
}

class _StepTrackerScreenState extends State<StepTrackerScreen> {
  Stream<StepCount>? _stepCountStream;
  StreamSubscription<StepCount>? _stepSub;

  int? _lastSensorValue;
  String _pedometerStatus = 'Not started';

  @override
  void initState() {
    super.initState();
    _initPedometer();             // start listening when screen opens
  }

  Future<void> _initPedometer() async {
    try {
      _stepCountStream = Pedometer.stepCountStream;
      _stepSub = _stepCountStream!.listen(
        _onStepData,
        onError: _onStepError,
      );

      setState(() {
        _pedometerStatus = 'Listening for steps...';
      });
    } catch (e) {
      setState(() {
        _pedometerStatus = 'Pedometer error: $e';
      });
    }
  }

  // Called every time the OS reports a new total step count
  Future<void> _onStepData(StepCount event) async {
    final int sensorSteps = event.steps;

    // First reading: just store it, no updates
    if (_lastSensorValue == null) {
      _lastSensorValue = sensorSteps;
      return;
    }

    final int delta = sensorSteps - _lastSensorValue!;
    _lastSensorValue = sensorSteps;

    if (delta <= 0) return;

    // Apply the new steps to Firestore
    await widget.characterRef.set({
      'steps': FieldValue.increment(delta),
      'xp': FieldValue.increment(delta),
      // keep daily quests in sync (step-based quests)
      'dailyQ1Progress': FieldValue.increment(delta),
      'dailyQ2Progress': FieldValue.increment(delta),
    }, SetOptions(merge: true));
    // UI uses a StreamBuilder on Firestore, so it will update itself.
  }

  void _onStepError(error) {
    setState(() {
      _pedometerStatus = 'Pedometer not available';
    });
  }

  @override
  void dispose() {
    _stepSub?.cancel(); // stop listening when leaving screen
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Step Tracker'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: widget.characterRef.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data?.data() ?? {};
                final name = (data['name'] ?? 'Unknown') as String;
                final charClass = (data['class'] ?? 'Unknown') as String;
                final steps = (data['steps'] ?? 0) as int;
                final xp = (data['xp'] ?? 0) as int;
                final level = (data['level'] ?? 1) as int;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$name the $charClass',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Steps: $steps', style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 4),
                    Text('XP: $xp'),
                    Text('Level: $level'),
                    const SizedBox(height: 8),
                    Text(
                      'Pedometer: $_pedometerStatus',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  // +100 steps and +10 XP each tap.
                  // SetOptions(merge: true) so other fields are kept.
                  await widget.characterRef.set({
                    'steps': FieldValue.increment(100),
                    'xp': FieldValue.increment(10),
                    'dailyProgress': FieldValue.increment(100),
                    'dailyQ2Progress': FieldValue.increment(100),
                  }, SetOptions(merge: true));
                },
                child: const Text('Add 100 Steps (and 10 XP)'),
              ),
            ),
            // Daily Quest screen
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DailyQuestScreen(
                        characterRef: widget.characterRef, // pass the same character
                      ),
                    ),
                  );
                },
                child: const Text('View Daily Quest'),
              ),
            ),
            // Battle screen
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BattleScreen(
                      characterRef: widget.characterRef,  // keeps XP tied to this character
                    ),
                  ),
                );
              },
              child: const Text('Go to Battle'),
            ),

            const SizedBox(height: 8),
            const Text(
              'Each tap updates this character\'s steps and XP.\n'
              'You can create multiple characters and track them separately.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
