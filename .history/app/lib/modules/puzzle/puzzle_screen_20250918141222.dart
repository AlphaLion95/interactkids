import 'package:flutter/material.dart';

class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({Key? key}) : super(key: key);

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  String selectedTheme = 'Zoo';
  final List<String> themes = ['Zoo', 'Sea', 'Jungle'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Puzzle')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: themes
                  .map(
                    (theme) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ChoiceChip(
                        label: Text(theme),
                        selected: selectedTheme == theme,
                        onSelected: (selected) {
                          setState(() {
                            selectedTheme = theme;
                          });
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const Divider(),
          Expanded(
            child: Center(
              child: Text('Puzzle Board for theme: ' + selectedTheme),
              // TODO: Replace with drag & drop puzzle board
            ),
          ),
        ],
      ),
    );
  }
}
