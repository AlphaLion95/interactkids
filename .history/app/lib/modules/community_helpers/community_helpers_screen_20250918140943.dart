import 'package:flutter/material.dart';

class CommunityHelpersScreen extends StatelessWidget {
  const CommunityHelpersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Community Helpers')),
      body: const Center(child: Text('Community Helpers Module')),
    );
  }
}
