import 'package:flutter/material.dart';

void main() => runApp(const InteractKidsApp());

class InteractKidsApp extends StatelessWidget {
  const InteractKidsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InteractKids',
      home: MainMenu(),
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
