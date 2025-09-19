import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InteractKids',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        fontFamily: 'Nunito',
      ),
      home: const Scaffold(
        body: Center(child: Text('InteractKids App Loaded!')),
      ),
    );
  }
}
