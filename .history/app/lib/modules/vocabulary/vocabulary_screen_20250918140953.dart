import 'package:flutter/material.dart';

class VocabularyScreen extends StatelessWidget {
  const VocabularyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vocabulary')),
      body: const Center(child: Text('Vocabulary Module')),
    );
  }
}
