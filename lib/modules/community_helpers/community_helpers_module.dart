// Community Helpers module entry
import 'package:flutter/material.dart';

class CommunityHelpersScreen extends StatelessWidget {
  const CommunityHelpersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Community Helpers')),
      body: const Center(
          child: Text('Community Helpers Module Coming Soon!',
              style: TextStyle(fontSize: 22))),
    );
  }
}
