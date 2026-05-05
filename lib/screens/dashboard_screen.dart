import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class DashboardScreen extends StatefulWidget {
  final Function(String)? onNavigateToTickets;
  const DashboardScreen({Key? key, this.onNavigateToTickets}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Dashboard Overview', style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.hardHat, size: 80, color: Colors.orange[400]),
            const SizedBox(height: 20),
            const Text(
              'Under Construction',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Halaman Dashboard sedang dalam pengembangan.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}