import 'package:flutter/material.dart';

void main() => runApp(const InteractKidsApp());

class InteractKidsApp extends StatelessWidget {
  const InteractKidsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InteractKids',
      home: Scaffold(
        appBar: AppBar(title: const Text('InteractKids Main Menu')),
        body: const Center(child: Text('Welcome to InteractKids!')),
      ),
    );
  }
}
