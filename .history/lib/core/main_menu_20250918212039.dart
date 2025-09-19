import 'package:flutter/material.dart';

class MainMenu extends StatelessWidget {
  const MainMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final features = [
      'Puzzle',
      'Matching',
      'Reading',
      'Writing',
      'Painting',
      'Community Helpers',
      'Planets',
      'Plants',
      'Geography',
      'Parts of the House',
      'Vocabulary',
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('InteractKids'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to InteractKids!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: features
                    .map(
                      (feature) => ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          textStyle: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        child: Text(feature),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}