import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'site_list_screen.dart'; // Ini halaman Node-B lu yang sekarang
import 'spbu_list_screen.dart'; // Ini halaman SPBU lu yang sekarang
import 'odc_search_screen.dart'; // Ini halaman pencarian ODC yang baru
import 'odp_nearest_screen.dart'; // Ini halaman pencarian ODP terdekat
import 'absensi_screen.dart'; // Ini halaman cek absensi

class SiteMenuScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Daftar Menu',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // 1. MENU DATA NODE-B (CNOP)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey[200]!),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.all(16),
              leading: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  LucideIcons.radioTower,
                  color: Colors.blue[700],
                ), // Icon tower sinyal
              ),
              title: Text(
                "Data Node-B",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Text("Manajemen lokasi site CNOP & Telkomsel"),
              trailing: Icon(LucideIcons.chevronRight, color: Colors.grey),
              onTap: () {
                // Arahin ke halaman list yang udah lu bikin sebelumnya
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SiteListScreen()),
                );
              },
            ),
          ),

          SizedBox(height: 12), // Jarak antar menu
          // 2. MENU DATA SPBU
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey[200]!),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.all(16),
              leading: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  LucideIcons.fuel,
                  color: Colors.red[700],
                ), // Icon pom bensin
              ),
              title: Text(
                "Data SPBU",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Text("Manajemen lokasi SPBU Pertamina"),
              trailing: Icon(LucideIcons.chevronRight, color: Colors.grey),
              onTap: () {
                // Arahin ke halaman list yang udah lu bikin sebelumnya
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SpbuListScreen()),
                );
              },
            ),
          ),

          SizedBox(height: 12), // Jarak antar menu
          // 3. MENU CEK ODC TERDEKAT
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey[200]!),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.all(16),
              leading: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  LucideIcons.mapPin,
                  color: Colors.green[700],
                ), // Icon untuk ODC/Lokasi
              ),
              title: Text(
                "Cari ODC",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Text("Pencarian lokasi ODC di sekitar Anda"),
              trailing: Icon(LucideIcons.chevronRight, color: Colors.grey),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => OdcSearchScreen()),
                );
              },
            ),
          ),

          SizedBox(height: 12), // Jarak antar menu
          // 4. MENU CARI ODP TERDEKAT
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey[200]!),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.all(16),
              leading: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  LucideIcons.navigation,
                  color: Colors.orange[700],
                ), // Icon untuk ODP/Navigasi
              ),
              title: Text(
                "Cari ODP Terdekat",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Text("Cari ODP dalam radius 250m dari lokasi Anda"),
              trailing: Icon(LucideIcons.chevronRight, color: Colors.grey),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => OdpNearestScreen()),
                );
              },
            ),
          ),

          SizedBox(height: 12), // Jarak antar menu
          // 5. MENU CEK ABSENSI
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey[200]!),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.all(16),
              leading: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  LucideIcons.calendar,
                  color: Colors.purple[700],
                ), // Icon kalender untuk absensi
              ),
              title: Text(
                "Cek Absensi",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Text("Laporan absensi berdasarkan NIK karyawan"),
              trailing: Icon(LucideIcons.chevronRight, color: Colors.grey),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AbsensiScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
