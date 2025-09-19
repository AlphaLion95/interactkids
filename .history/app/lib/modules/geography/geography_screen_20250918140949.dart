import 'package:flutter/material.dart';

class GeographyScreen extends StatelessWidget {
  const GeographyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Geography')),
      body: const Center(child: Text('Geography Module')),
    );
  }
}
