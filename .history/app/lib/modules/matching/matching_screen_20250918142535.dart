import 'package:flutter/material.dart';
import '../../core/models.dart';

class MatchingScreen extends StatefulWidget {
  const MatchingScreen({Key? key}) : super(key: key);

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen> {
  MatchingType selectedType = MatchingType.pictureToWord;
  final List<MatchingType> types = [MatchingType.pictureToWord, MatchingType.wordToWord];

  // Placeholder for uploaded images and words
  final List<MatchingItem> items = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Matching')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: types.map((type) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ChoiceChip(
                  label: Text(_typeLabel(type)),
                  selected: selectedType == type,
                  onSelected: (selected) {
                    setState(() {
                      selectedType = type;
                    });
                  },
                ),
              )).toList(),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                // TODO: Implement image upload
              },
              child: const Text('Upload Image'),
            ),
          ),
          Expanded(
            child: Center(
              child: Text('Matching blocks will appear here.'),
              // TODO: Display matching blocks based on selectedType and items
            ),
          ),
        ],
      ),
    );
  }

  String _typeLabel(MatchingType type) {
    switch (type) {
      case MatchingType.pictureToWord:
        return 'Picture to Word';
      case MatchingType.wordToWord:
        return 'Word to Word';
    }
  }
}
