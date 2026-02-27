import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wan_monitor/screens/main_screen.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 1. UBAH CONTROLLER MENJADI NIK
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);

    try {
      final response = await ApiService.post('/login', {
        'nik': _nikController.text,
        'password': _passwordController.text,
      });

      final data = jsonDecode(response.body);

      // KUNCI PERBAIKAN: Ambil dari 'access_token' sesuai response Laravel kamu
      String? token = data['access_token'];
      Map<String, dynamic>? userData = data['user'];

      // Jika sukses login dan token ada
      if (response.statusCode == 200 && token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);

        if (userData != null) {
          await prefs.setString('role', userData['role'] ?? 'teknisi');
          await prefs.setString('name', userData['name'] ?? 'User');
        }

        if (!mounted) return;

        // Langsung meluncur ke Dashboard!
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainScreen()),
        );
      } else {
        _showError(data['message'] ?? 'Login gagal.');
      }
    } catch (e) {
      print("CRASH LOGIN: $e");
      _showError('Terjadi kesalahan internal. Cek console.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "WAN Monitor",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),

              // 3. UBAH TAMPILAN TEXTFIELD MENJADI NIK
              TextField(
                controller: _nikController,
                keyboardType:
                    TextInputType.number, // Memunculkan keyboard angka otomatis
                decoration: InputDecoration(
                  labelText: 'NIK',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(
                    Icons.badge,
                  ), // Ubah icon jadi semacam ID Card
                ),
              ),

              SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue[700],
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'MASUK',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
