import 'package:flutter/material.dart';

// Reading module entry
class ReadingScreen extends StatelessWidget {
  const ReadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reading')),
      body: const Center(child: Text('Reading Module Coming Soon!', style: TextStyle(fontSize: 22))),
    );
  }
}
