import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'site_list_screen.dart';
import 'spbu_list_screen.dart';
import 'odc_search_screen.dart';
import 'odp_nearest_screen.dart';
import 'absensi_screen.dart';
import 'schedule_screen.dart';

class SiteMenuScreen extends StatelessWidget {
  const SiteMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Daftar Menu',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.0,
        children: [
          // 1. DATA NODE-B
          _buildMenuCard(
            context,
            title: "Data Node-B",
            icon: LucideIcons.radioTower,
            color: Colors.blue,
            // HAPUS CONST DI SINI
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SiteListScreen()),
            ),
          ),

          // 2. DATA SPBU
          _buildMenuCard(
            context,
            title: "Data SPBU",
            icon: LucideIcons.fuel,
            color: Colors.red,
            // HAPUS CONST DI SINI
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SpbuListScreen()),
            ),
          ),

          // 3. CARI ODC
          _buildMenuCard(
            context,
            title: "Cari ODC",
            icon: LucideIcons.mapPin,
            color: Colors.green,
            // HAPUS CONST DI SINI
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => OdcSearchScreen()),
            ),
          ),

          // 4. CARI ODP
          _buildMenuCard(
            context,
            title: "Cari ODP",
            icon: LucideIcons.navigation,
            color: Colors.orange,
            // HAPUS CONST DI SINI
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => OdpNearestScreen()),
            ),
          ),

          // 5. CEK ABSENSI
          _buildMenuCard(
            context,
            title: "Cek Absensi",
            icon: LucideIcons.calendar,
            color: Colors.purple,
            // HAPUS CONST DI SINI
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AbsensiScreen()),
            ),
          ),

          // 6. JADWAL PIKET SA
          _buildMenuCard(
            context,
            title: "Jadwal Piket",
            icon: LucideIcons.calendarClock,
            color: Colors.teal,
            // HAPUS CONST DI SINI
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ScheduleScreen()),
            ),
          ),
        ],
      ),
    );
  }

  // JURUS HELPER BIAR KODINGAN RAPI & NGGAK BIKIN SAKIT MATA
  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required MaterialColor color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: color.shade100.withOpacity(0.5),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color.shade700, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
