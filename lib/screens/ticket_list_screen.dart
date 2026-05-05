import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class TicketListScreen extends StatefulWidget {
  final String initialFilter;
  const TicketListScreen({Key? key, this.initialFilter = 'All'}) : super(key: key);

  @override
  _TicketListScreenState createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 60, 16, 8),
          color: Colors.white,
          child: Row(
            children: const [
              Text('Ticket List', 
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
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
                  'Halaman Daftar Tiket sedang dalam pengembangan.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}