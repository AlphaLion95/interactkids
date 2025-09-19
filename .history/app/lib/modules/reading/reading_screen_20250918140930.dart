import 'package:flutter/material.dart';

class ReadingScreen extends StatelessWidget {
  const ReadingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reading')),
      body: const Center(child: Text('Reading Module')),
    );
  }
}
