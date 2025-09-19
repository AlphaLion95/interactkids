import 'package:flutter/material.dart';

class PlantsScreen extends StatelessWidget {
  const PlantsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plants')),
      body: const Center(child: Text('Plants Module')),
    );
  }
}
