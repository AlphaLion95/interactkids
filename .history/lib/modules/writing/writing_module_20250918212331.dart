import 'package:flutter/material.dart';

// Writing module entry
class WritingScreen extends StatelessWidget {
  const WritingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Writing')),
      body: const Center(child: Text('Writing Module Coming Soon!', style: TextStyle(fontSize: 22))),
    );
  }
}
