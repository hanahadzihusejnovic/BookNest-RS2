import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const BookNestAdminApp());
}

class BookNestAdminApp extends StatelessWidget {
  const BookNestAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BookNest Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.gantariTextTheme(),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
