import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart'; // Import ini
import 'firebase_options.dart'; // File ini otomatis dibikin sama flutterfire tadi

// Pastikan import ini bener sesuai struktur folder lu
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

void main() async {
  // PENTING: Wajib ada ini sebelum jalanin Firebase
  WidgetsFlutterBinding.ensureInitialized();
  
  // Nyalain mesin Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WAN Monitor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
        primarySwatch: Colors.blue,
      ),
      // INI KUNCINYA: Pakai parameter 'home' dan FutureBuilder
      home: FutureBuilder<SharedPreferences>(
        future: SharedPreferences.getInstance(),
        builder: (context, snapshot) {
          // 1. Selagi nunggu ngecek memori HP, tampilin loading muter di tengah
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Colors.white,
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // 2. Baca memori tokennya
          final prefs = snapshot.data;
          final token = prefs?.getString('token');

          // 3. Penentuan Jalur Suci
          if (token != null && token.isNotEmpty) {
            // Kalau token ada -> BUKA MAIN SCREEN (Biar Navbar ngikut!)
            return MainScreen(); 
          } else {
            // Kalau token kosong -> BUKA LOGIN SCREEN
            return const LoginScreen();
          }
        },
      ),
    );
  }
}