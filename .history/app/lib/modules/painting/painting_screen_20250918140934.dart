import 'package:flutter/material.dart';

class PaintingScreen extends StatelessWidget {
  const PaintingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Painting')),
      body: const Center(child: Text('Painting Module')),
    );
  }
}
