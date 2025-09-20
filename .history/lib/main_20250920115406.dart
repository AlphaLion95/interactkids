import 'package:flutter/material.dart';
import 'core/main_menu.dart';

void main() {
  runApp(const InteractKidsApp());
}

class InteractKidsApp extends StatelessWidget {
  const InteractKidsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InteractKids',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        fontFamily: 'Nunito',
      ),
      home: const MainMenu(),
    );
  }
}
