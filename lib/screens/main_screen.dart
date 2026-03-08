import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'dashboard_screen.dart';
import 'ticket_list_screen.dart';
import 'site_menu_screen.dart'; 
import 'profile_screen.dart';
import 'create_ticket_screen.dart';
import 'absen_screen.dart'; 
import '../services/api_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  String userRole = '';
  String _ticketFilter = 'All';
  
  // Variabel sakti biar aplikasi gak nembak API terus-terusan
  bool _sudahAbsen = false; 
  
  // Kunci ghaib buat maksa dashboard reload pas diklik
  int _dashboardRefreshKey = 0; 

  // JURUS SEDOT FCM & NANGKEP NOTIF
  Future<void> _setupFCM() async {
    // TAMBAHIN INI JING: Kalau jalan di Web, langsung kabur!
    if (kIsWeb) {
      print("Ini di Web Bos, skip narik token FCM biar Chrome nggak meledak!");
      return; 
    }

    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // 1. Minta izin dulu ke satpam HP
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Izin notif dikasih Bos!');
      
      // 2. Tarik Token-nya
      String? token = await messaging.getToken();
      print("KTP HP INI (FCM TOKEN): $token");

      // 3. Lempar ke API Laravel lu
      if (token != null) {
        try {
          await ApiService.post('/update-fcm', {'fcm_token': token});
          print("Mantap! Token sukses mendarat di database GCP.");
        } catch (e) {
          print("Gagal setor token ke server: $e");
        }
      }

      // 4. JARING NOTIF PAS APLIKASI LAGI DIBUKA (FOREGROUND)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Dapet peluru notif nih pas lagi buka app!');
        
        if (message.notification != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.notification!.title ?? 'Notif Baru', 
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.notification!.body ?? '',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              backgroundColor: Colors.blue.shade800,
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating, // Biar ngambang cakep
              margin: const EdgeInsets.only(top: 50, left: 20, right: 20), // Munculin dari atas
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      });

    } else {
      print('Yah, izin notif ditolak jing!');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _setupFCM();
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userRole = (prefs.getString('role') ?? 'teknisi').toLowerCase().trim();
    });
  }

  void _navigateToTickets(String filter) {
    setState(() {
      _ticketFilter = filter;
      _currentIndex = 1;
    });
  }

  // JURUS SATPAM BOTTOM NAVBAR
  void _onItemTapped(int index) async {
    // Dashboard (0), Absen (2), sama Profil (4) bebas masuk
    if (index != 0 && index != 2 && index != 4) {
      if (!_sudahAbsen) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );

        try {
          final response = await ApiService.get('/absen-status');
          Navigator.pop(context); // Tutup loading

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['status'] == 'belum_absen') {
              // KETAHUAN BELUM ABSEN MASUK!
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Woy absen masuk dulu jing sebelum buka menu ini!'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 3),
                ),
              );
              setState(() {
                _currentIndex = 2;
              });
              return; 
            } else {
              _sudahAbsen = true;
            }
          }
        } catch (e) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal ngecek server Bos! Cek koneksi lu.'), backgroundColor: Colors.red),
          );
          return;
        }
      }
    }

    // PINDAH TAB NORMAL
    setState(() {
      _currentIndex = index;
      
      // Nah ini kuncinya biar Dashboard ke-refresh otomatis
      if (index == 0) {
        _dashboardRefreshKey++; 
      }
      
      if (index == 1) {
        _ticketFilter = 'All';
      }
      
      _loadUserRole();
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      DashboardScreen(
        key: ValueKey('dash_$_dashboardRefreshKey'), // <--- Kunci ghaib dipasang dimari
        onNavigateToTickets: _navigateToTickets,
      ), 
      TicketListScreen(
        key: ValueKey('ticket_$_ticketFilter'),
        initialFilter: _ticketFilter,
      ), 
      const AbsenScreen(), 
      SiteMenuScreen(), 
      ProfileScreen(), 
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),

      floatingActionButton:
          (_currentIndex == 1 &&
              (userRole == 'helpdesk' || userRole == 'admin'))
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateTicketScreen()),
                );
                if (result == true) {
                  setState(() {}); 
                }
              },
              backgroundColor: Colors.blue[700],
              child: const Icon(LucideIcons.plus, color: Colors.white),
            )
          : null,

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped, 
        selectedItemColor: Colors.blue[700],
        unselectedItemColor: Colors.grey[400],
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.layoutDashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.ticket),
            label: 'Tiket',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.scanFace),
            label: 'Absen',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.mapPin),
            label: 'Menu',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.user),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}