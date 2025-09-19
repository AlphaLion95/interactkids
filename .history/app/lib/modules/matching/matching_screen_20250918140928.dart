import 'package:flutter/material.dart';

class MatchingScreen extends StatelessWidget {
  const MatchingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Matching')),
      body: const Center(child: Text('Matching Module')),
    );
  }
}
