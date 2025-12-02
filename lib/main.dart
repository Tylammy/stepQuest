import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
        useMaterial3: true,),
      home: const CharacterListScreen(),
    );
  }
}

/// ------------------------------------------------------------
/// WEEK 1: CHARACTER LIST SCREEN
/// ------------------------------------------------------------
/// This screen will eventually:
///  - Display all characters the user has created
///  - Allow selecting/editing characters
///  - Provide a button to create a new character
///
/// This is a placeholder with a "Create Character" button.
class CharacterListScreen extends StatelessWidget {
  const CharacterListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Characters"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "No characters yet!",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const Text(
              "Create your first hero to begin your adventure.",
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 24),

            // Navigates to the Character Creation Screen
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    // Creates and displays the CharacterCreationScreen
                    builder: (context) => const CharacterCreationScreen(),
                  ),
                );
              },
              child: const Text("Create Character"),
            ),
          ],
        ),
      ),
    );
  }
}

/// Character Creation Screen
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

            // Temporary "Save Character" button, this just shows the entered info in a pop-up box
            ElevatedButton(
              onPressed: () {
                final name = _nameController.text;

                // Name can't be empty
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Name cannot be empty"),
                    ),
                  );
                  return;
                }

                // Shows confirmation
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Character Created!"),
                    content: Text("Name: $name\nClass: $selectedClass"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("OK"),
                      ),
                    ],
                  ),
                );
              },
              child: const Text("Save Character"),
            ),
          ],
        ),
      ),
    );
  }
}
