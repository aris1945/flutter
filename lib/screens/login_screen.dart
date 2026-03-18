import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:wan_monitor/screens/main_screen.dart'; // Pastiin path ini bener ya Bos
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controller pake NIK sesuai kodingan lu
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscureText = true;
  bool _isLoading = false;
  String _errorMessage = '';

  // MESIN LOGIN ASLI BUATAN LU YANG UDAH GUE POLES DIKIT
  Future<void> _login() async {
    // Validasi form biar gak diklik pas kosong
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = ''; // Bersihin error sebelumnya
    });

    try {
      final response = await ApiService.post('/login', {
        'nik': _nikController.text.trim(),
        'password': _passwordController.text,
      });

      final data = jsonDecode(response.body);

      // Tangkap token dan data user
      String? token = data['access_token'];
      Map<String, dynamic>? userData = data['user'];

      if (response.statusCode == 200 && token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);

        if (userData != null) {
          await prefs.setString('role', userData['role'] ?? 'teknisi');
          await prefs.setString('name', userData['name'] ?? 'User');
        }

        if (!mounted) return;

        // Meluncur ke Dashboard!
        // Meluncur ke Dashboard pake Animasi VIP!
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const MainScreen(),
            transitionDuration: const Duration(
              milliseconds: 700,
            ), // Durasi animasi (makin gede makin pelan)
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  // 1. Efek Pudar (Fade In)
                  var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
                      .animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOut,
                        ),
                      );

                  // 2. Efek Zoom Halus (Scale)
                  var scaleAnimation = Tween<double>(begin: 0.9, end: 1.0)
                      .animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      );

                  // Gabungin dua efeknya
                  return FadeTransition(
                    opacity: fadeAnimation,
                    child: ScaleTransition(scale: scaleAnimation, child: child),
                  );
                },
          ),
        );
      } else {
        // Tembakin pesan error ke UI kotak merah
        setState(
          () => _errorMessage =
              data['message'] ?? 'Login gagal Bos! Cek lagi NIK/Password.',
        );
      }
    } catch (e) {
      print("CRASH LOGIN: $e");
      setState(
        () => _errorMessage =
            'Server ngambek atau inet lu putus jing! Cek console.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ==========================================
          // LAYER 1: BACKGROUND GRADASI BIRU KEREN
          // ==========================================
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue.shade900,
                  Colors.blue.shade600,
                  Colors.blue.shade400,
                  Colors.grey.shade50,
                ],
                stops: const [0.0, 0.3, 0.5, 0.8],
              ),
            ),
          ),

          // ==========================================
          // LAYER 2: KONTEN UTAMA
          // ==========================================
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 40.0,
              ),
              child: Column(
                children: [
                  // --- HEADER: LOGO & JUDUL ---
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.radioTower,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'WanMonitor v1.0',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sistem Monitoring Jaringan B2B',
                    style: TextStyle(color: Colors.blue.shade100, fontSize: 14),
                  ),
                  const SizedBox(height: 50),

                  // --- FORM LOGIN (KOTAK MELAYANG) ---
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Silakan Login',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Gunakan NIK karyawan Anda',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 30),

                          // ERROR MESSAGE ALERT
                          if (_errorMessage.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    LucideIcons.alertTriangle,
                                    color: Colors.red.shade700,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _errorMessage,
                                      style: TextStyle(
                                        color: Colors.red.shade800,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // --- INPUT NIK ---
                          _buildTextField(
                            controller: _nikController,
                            label: 'NIK',
                            hint: 'Masukkan NIK lu',
                            icon: LucideIcons
                                .badge, // Pake ikon badge sesuai request lu
                            keyboardType: TextInputType.number,
                            validator: (value) => value == null || value.isEmpty
                                ? 'NIK wajib diisi jing'
                                : null,
                          ),
                          const SizedBox(height: 20),

                          // --- INPUT PASSWORD ---
                          _buildTextField(
                            controller: _passwordController,
                            label: 'Password',
                            hint: 'Masukkan password',
                            icon: LucideIcons.lock,
                            obscureText: _obscureText,
                            keyboardType: TextInputType.visiblePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureText
                                    ? LucideIcons.eye
                                    : LucideIcons.eyeOff,
                                color: Colors.grey,
                                size: 18,
                              ),
                              onPressed: () =>
                                  setState(() => _obscureText = !_obscureText),
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Password jangan kosong jing'
                                : null,
                          ),
                          const SizedBox(height: 15),

                          // --- LUPA PASSWORD ---
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Hubungi tim helpdesk pusat Bos!',
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              },
                              child: Text(
                                'Lupa Password?',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),

                          // --- TOMBOL MASUK ---
                          SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade700,
                                foregroundColor: Colors.white,
                                elevation: 5,
                                shadowColor: Colors.blue.shade200,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : const Text(
                                      'MASUK',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        letterSpacing: 1,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // --- FOOTER ---
                  const SizedBox(height: 50),
                  Text(
                    '© 2024 PT. Telkom Akses',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  Text(
                    'Wajib login menggunakan jaringan internal/VPN',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET HELPER BUAT FORM
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(icon, color: Colors.blue.shade600, size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade300),
            ),
          ),
        ),
      ],
    );
  }
}
