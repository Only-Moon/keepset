import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'Screens/app_shell.dart';
import 'theme/keepset_colors.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Keepset',
      debugShowCheckedModeBanner: false,
      home: const AppShell(),
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: KeepsetColors.base,
        textTheme: GoogleFonts.ralewayTextTheme(),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: KeepsetColors.base,
        textTheme: GoogleFonts.ralewayTextTheme(),
      ),
    );
  }
}
