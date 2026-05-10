import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey = 'pk_test_51TMA9zBzufS6quu6NAkgt4pkEnR7TMe2VfvAiep4fzxZ8cAmBt1I6iDREcXHi1DJ1iG7yu4u0DU8e8rZAdgY1o3p00I3obeviS';
  await Stripe.instance.applySettings();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BookNest',
      debugShowCheckedModeBanner: false, 
      theme: ThemeData(
        textTheme: GoogleFonts.gantariTextTheme(),
        useMaterial3: true,
      ),
      home: const AuthWrapper(), 
    );
  }
}