import 'package:flutter/material.dart';

// Matching module entry
class MatchingScreen extends StatelessWidget {
  const MatchingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Matching')),
      body: const Center(
          child: Text('Matching Module Coming Soon!', style: TextStyle(fontSize: 22))),
    );
  }
}
