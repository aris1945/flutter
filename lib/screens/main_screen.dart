import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dashboard_screen.dart';
import 'ticket_list_screen.dart';
import 'profile_screen.dart'; // Import layar profil
import 'create_ticket_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  String userRole = '';

  // Sekarang ada 3 halaman
  final List<Widget> _pages = [
    DashboardScreen(),
    TicketListScreen(),
    ProfileScreen(),
  ];
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      floatingActionButton: _currentIndex == 1 
      ? FloatingActionButton(
          onPressed: () async {
            // Pastikan import CreateTicketScreen sudah ada di atas
            final result = await Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => CreateTicketScreen())
            );
            // Refresh data bisa dilakukan dengan memicu state di TicketListScreen
            if (result == true) {
              setState(() {}); // Memicu rebuild
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
          });
          
        },
        selectedItemColor: Colors.blue[700],
        unselectedItemColor: Colors.grey[400],
        showUnselectedLabels: true,
        backgroundColor: Colors.white,
        elevation: 10,
        type: BottomNavigationBarType.fixed, // Biar icon-nya gak gerak-gerak aneh
        items: const [
          BottomNavigationBarItem(icon: Icon(LucideIcons.layoutDashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.ticket), label: 'Tiket'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.user), label: 'Profil'),
        ],
      ),
    );
  }
}