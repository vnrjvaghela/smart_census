import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:smart_census/screens/auth/splash_screen.dart';
import 'package:smart_census/services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print("Firebase initialization failed: $e");
    print("Running without Firebase (some features may not work).");
  }
  await DatabaseService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Census',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32), // Primary Green
          brightness: Brightness.light,
          primary: const Color(0xFF2E7D32), // India flag green
          secondary: const Color(0xFFFF6F00), // India flag saffron
          tertiary: const Color(0xFF1976D2), // Trust Blue
          surface: const Color(0xFFFAFAFA), // Soft Background
          error: const Color(0xFFD32F2F), // Error Red
        ),
        textTheme: GoogleFonts.robotoTextTheme(), // Official Government Font
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent, // Clean translucent look
          titleTextStyle: GoogleFonts.roboto(
            color: const Color(0xFF212121), // Text Primary
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
          iconTheme: const IconThemeData(color: Color(0xFF212121)),
        ),
        cardTheme: CardThemeData(
          elevation: 2, 
          shadowColor: const Color(0xFF2E7D32).withOpacity(0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Modern slightly rounded
          ),
          color: const Color(0xFFFFFFFF),
          surfaceTintColor: Colors.transparent,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shadowColor: const Color(0xFF2E7D32).withOpacity(0.3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), // Perfect pill shape for buttons
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            textStyle: GoogleFonts.roboto(fontWeight: FontWeight.w600, fontSize: 16, letterSpacing: 0.5),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none, // iOS style no border usually, just fill
          ),
          enabledBorder: OutlineInputBorder(
             borderRadius: BorderRadius.circular(12),
             borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF4285F4), width: 2),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
