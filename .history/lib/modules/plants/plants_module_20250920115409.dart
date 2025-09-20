// Plants module entry
import 'package:flutter/material.dart';

class PlantsScreen extends StatelessWidget {
  const PlantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plants')),
      body: const Center(
          child: Text('Plants Module Coming Soon!',
              style: TextStyle(fontSize: 22))),
    );
  }
}
