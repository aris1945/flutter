import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String userName = 'Loading...';
  String userRole = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('name') ?? 'Teknisi Andalan';
      userRole = prefs.getString('role') ?? 'teknisi';
    });
  }

  void _logout() async {
    // 1. Bersihin semua memori (token, nama, role)
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    // Pengecekan wajib biar linter nggak ngomel
    if (!mounted) return; 

    // 2. Kasih notif sukses
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Berhasil Logout!')),
    );

    // 3. Lempar ke Login & HANCURKAN riwayat halaman
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false, // Kunci maut: Bikin user nggak bisa pencet tombol "Back" di HP buat masuk lagi
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Profil', style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // HEADER PROFIL
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue[700],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(LucideIcons.user, size: 30, color: Colors.blue[700]),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName, 
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                      ),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          userRole.toUpperCase(), 
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          
          SizedBox(height: 32),

          // MENU LOGOUT DOANG
          Text("AKUN", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[500])),
          SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                child: Icon(LucideIcons.logOut, color: Colors.red[700]),
              ),
              title: Text("Logout", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[700])),
              onTap: _logout,
            ),
          ),
        ],
      ),
    );
  }
}