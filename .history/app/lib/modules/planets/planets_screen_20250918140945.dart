import 'package:flutter/material.dart';

class PlanetsScreen extends StatelessWidget {
  const PlanetsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Planets')),
      body: const Center(child: Text('Planets Module')),
    );
  }
}
