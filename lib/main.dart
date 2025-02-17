import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'models/chore_state.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ChoreState(),
      child: const ChoreApp(),
    ),
  );
}

class ChoreApp extends StatelessWidget {
  const ChoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChorePal',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const LoginScreen(),
    );
  }
}