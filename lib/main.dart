import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const InciGidaApp());
}

class InciGidaApp extends StatelessWidget {
  const InciGidaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'İnci Gıda',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF2E7D32),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true),
      ),
      home: const HomeScreen(),
    );
  }
}
