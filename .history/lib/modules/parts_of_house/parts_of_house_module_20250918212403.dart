import 'package:flutter/material.dart';

// Parts of the House module entry

class PartsOfHouseScreen extends StatelessWidget {
  const PartsOfHouseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Parts of the House')),
      body: const Center(
          child: Text('Parts of the House Module Coming Soon!',
              style: TextStyle(fontSize: 22))),
    );
  }
}
