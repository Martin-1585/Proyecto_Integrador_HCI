import 'package:flutter/material.dart';
import 'package:panel_control/screens/screens.dart';

void main() {
  runApp(const MyReactorApp());
}

class MyReactorApp extends StatelessWidget {
  const MyReactorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Panel Nuclear',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
        useMaterial3: true,
      ),
      home: const ControlRoomPage(),
    );
  }
}
