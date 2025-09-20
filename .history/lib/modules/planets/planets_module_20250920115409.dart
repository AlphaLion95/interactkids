import 'package:flutter/material.dart';

// Planets module entry
class PlanetsScreen extends StatelessWidget {
  const PlanetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Planets')),
      body: const Center(
          child: Text('Planets Module Coming Soon!',
              style: TextStyle(fontSize: 22))),
    );
  }
}
