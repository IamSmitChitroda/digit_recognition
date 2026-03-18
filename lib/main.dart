import 'package:flutter/material.dart';
import 'screens/recognition_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digit Recognition',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0D1A),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF7C4DFF),
          secondary: const Color(0xFF448AFF),
          surface: const Color(0xFF161630),
          onSurface: Colors.grey.shade200,
        ),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const RecognitionScreen(),
    );
  }
}
