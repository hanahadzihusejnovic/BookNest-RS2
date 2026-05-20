import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/auth_wrapper.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BookNestAdminApp());
}

class BookNestAdminApp extends StatelessWidget {
  const BookNestAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'BookNest Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.gantariTextTheme(),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}
