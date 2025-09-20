import 'package:flutter/material.dart';

// Vocabulary module entry
class VocabularyScreen extends StatelessWidget {
  const VocabularyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vocabulary')),
      body: const Center(
          child: Text('Vocabulary Module Coming Soon!',
              style: TextStyle(fontSize: 22))),
    );
  }
}
