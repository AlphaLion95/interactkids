import 'package:flutter/material.dart';

class PuzzleScreen extends StatelessWidget {
  const PuzzleScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Puzzle')),
      body: const Center(child: Text('Puzzle Module')),
    );
  }
}
