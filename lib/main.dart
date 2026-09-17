import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SumTenApp());
}

class SumTenApp extends StatelessWidget {
  const SumTenApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1F7A56),
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'Sum Ten',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: colorScheme,
        textTheme: GoogleFonts.frauncesTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ).apply(
          displayColor: const Color(0xFFF3F7F1),
          bodyColor: const Color(0xFFE6F0EA),
        ).copyWith(
          titleMedium: GoogleFonts.dmSans(
            color: const Color(0xFFE6F0EA),
            fontWeight: FontWeight.w500,
          ),
          bodyMedium: GoogleFonts.dmSans(
            color: const Color(0xFFE6F0EA),
          ),
          labelLarge: GoogleFonts.dmSans(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
