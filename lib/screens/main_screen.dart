import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dashboard_screen.dart';
import 'ticket_list_screen.dart';
import 'site_list_screen.dart'; // <--- IMPORT HALAMAN SITE
import 'profile_screen.dart';
import 'create_ticket_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  String userRole = '';

  // 1. TAMBAHIN SITELISTSCREEN DI SINI (Index ke-2)
  final List<Widget> _pages = [
    DashboardScreen(),   // Index 0
    TicketListScreen(),  // Index 1
    SiteListScreen(),    // Index 2 <--- TAB BARU
    ProfileScreen(),     // Index 3 (Profil geser ke kanan)
  ];

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userRole = (prefs.getString('role') ?? 'teknisi').toLowerCase().trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      
      // Tombol tambah tiket tetep jalan khusus di tab Tiket (index 1)
      floatingActionButton: (_currentIndex == 1 && (userRole == 'helpdesk' || userRole == 'admin')) 
        ? FloatingActionButton(
            onPressed: () async {
              final result = await Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => CreateTicketScreen())
              );
              if (result == true) {
                setState(() {}); // Refresh list kalau abis nambah tiket
              }
            },
            backgroundColor: Colors.blue[700],
            child: Icon(LucideIcons.plus, color: Colors.white),
          )
        : null,

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            _loadUserRole();
          });
        },
        selectedItemColor: Colors.blue[700],
        unselectedItemColor: Colors.grey[400],
        // PENTING: type fixed wajib dipakai kalau tab-nya 4 atau lebih
        type: BottomNavigationBarType.fixed, 
        items: const [
          BottomNavigationBarItem(icon: Icon(LucideIcons.layoutDashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.ticket), label: 'Tiket'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.mapPin), label: 'Site'), // <--- ICON BARU
          BottomNavigationBarItem(icon: Icon(LucideIcons.user), label: 'Profil'),
        ],
      ),
    );
  }
}