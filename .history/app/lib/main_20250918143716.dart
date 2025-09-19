import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appDocDir = await getApplicationDocumentsDirectory();
  Hive.init(appDocDir.path);
  await Hive.openBox('settings');
  runApp(const InteractKidsApp());
}

class InteractKidsApp extends StatelessWidget {
  const InteractKidsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InteractKids',
      home: FutureBuilder(
        future: Hive.box('settings').get('voice'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.data == null) {
            return const VoiceSelectionScreen();
          }
          return MainMenu();
        },
      ),
    );
  }
}

class MainMenu extends StatelessWidget {
  final List<_MenuItem> menuItems = const [
    _MenuItem('Puzzle', Icons.extension, 'PuzzleModule'),
    _MenuItem('Matching', Icons.link, 'MatchingModule'),
    _MenuItem('Reading', Icons.menu_book, 'ReadingModule'),
    _MenuItem('Writing', Icons.edit, 'WritingModule'),
    _MenuItem('Painting', Icons.brush, 'PaintingModule'),
    _MenuItem('Community Helpers', Icons.people, 'CommunityHelpersModule'),
    _MenuItem('Planets', Icons.public, 'PlanetsModule'),
    _MenuItem('Plants', Icons.local_florist, 'PlantsModule'),
    _MenuItem('Geography', Icons.map, 'GeographyModule'),
    _MenuItem('Parts of House', Icons.home, 'PartsOfHouseModule'),
    _MenuItem('Vocabulary', Icons.text_fields, 'VocabularyModule'),
  ];

  MainMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('InteractKids Main Menu')),
      body: ListView.builder(
        itemCount: menuItems.length,
        itemBuilder: (context, index) {
          final item = menuItems[index];
          return ListTile(
            leading: Icon(item.icon),
            title: Text(item.title),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => _ModuleScreen(title: item.title),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _MenuItem {
  final String title;
  final IconData icon;
  final String route;
  const _MenuItem(this.title, this.icon, this.route);
}

class _ModuleScreen extends StatelessWidget {
  final String title;
  const _ModuleScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('Welcome to $title!')),
    );
  }
}

class VoiceSelectionScreen extends StatefulWidget {
  const VoiceSelectionScreen({super.key});

  @override
  State<VoiceSelectionScreen> createState() => _VoiceSelectionScreenState();
}

class _VoiceSelectionScreenState extends State<VoiceSelectionScreen> {
  String? selectedVoice;
  final List<_VoiceOption> voices = const [
    _VoiceOption('Brycen', 'Boy voice (Crocodile)', 'brycen'),
    _VoiceOption('Yliana', 'Girl voice (Panda)', 'yliana'),
    _VoiceOption('Kaida', 'Baby voice (Dog)', 'kaida'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Your Voice')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Select a voice for the app:', style: TextStyle(fontSize: 20)),
          const SizedBox(height: 24),
          ...voices.map((voice) => RadioListTile<String>(
                title: Text('${voice.name} - ${voice.desc}'),
                value: voice.key,
                groupValue: selectedVoice,
                onChanged: (value) {
                  setState(() {
                    selectedVoice = value;
                  });
                },
              )),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: selectedVoice == null
                ? null
                : () async {
                    await Hive.box('settings').put('voice', selectedVoice);
                    if (mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => MainMenu()),
                      );
                    }
                  },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

class _VoiceOption {
  final String name;
  final String desc;
  final String key;
  const _VoiceOption(this.name, this.desc, this.key);
}
