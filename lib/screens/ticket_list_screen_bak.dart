import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'ticket_detail_screen.dart';
import 'create_ticket_screen.dart';

class TicketListScreen extends StatefulWidget {
  final String initialFilter;
  const TicketListScreen({Key? key, this.initialFilter = 'All'}) : super(key: key);

  @override
  _TicketListScreenState createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen> {
  List<dynamic> allTickets = [];
  List<dynamic> filteredTickets = [];
  bool isLoading = true;
  String userRole = '';
  String selectedFilter = 'All'; 
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedFilter = widget.initialFilter;
    _loadUserRole();
    _fetchTickets();
  }

  @override
  void didUpdateWidget(covariant TicketListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFilter != widget.initialFilter) {
      setState(() {
        selectedFilter = widget.initialFilter;
      });
      _fetchTickets();
    }
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedRole = prefs.getString('role');
    setState(() {
      userRole = (storedRole ?? 'teknisi').toLowerCase().trim();
    });
  }

  Future<void> _fetchTickets({String query = ''}) async {
    setState(() => isLoading = true);
    try {
      // Selalu ambil semua tiket dari API
      String url = '/tickets?search=$query';

      final response = await ApiService.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          allTickets = data['data']['data'] ?? [];
          _applyFilter();
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error fetch tickets: $e");
      setState(() => isLoading = false);
    }
  }

  void _applyFilter() {
    if (selectedFilter == 'All') {
      filteredTickets = List.from(allTickets);
    } else {
      filteredTickets = allTickets.where((ticket) {
        final status = (ticket['status'] ?? '').toString().toLowerCase();
        final filter = selectedFilter.toLowerCase();
        return status == filter;
      }).toList();
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open': return Colors.red;
      case 'closed': return Colors.green;
      case 'in progress': return Colors.orange;
      default: return Colors.blue;
    }
  }

  @override
Widget build(BuildContext context) {
  return Column(
    children: [
      // Bagian AppBar Manual (Biar Navbar gak ketutup)
      Container(
        padding: EdgeInsets.fromLTRB(16, 60, 16, 8),
        color: Colors.white,
        child: Row(
          children: [
            Text('Ticket List', 
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)
            ),
          ],
        ),
      ),
      
      // Bagian Search
      Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: TextField(
          controller: _searchController,
          onSubmitted: (value) => _fetchTickets(query: value),
          decoration: InputDecoration(
            hintText: 'Cari site atau nomor...',
            prefixIcon: Icon(LucideIcons.search, size: 18),
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none
            ),
          ),
        ),
      ),

      // Tab Filter Status
      Container(
        height: 50,
        color: Colors.white,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 12),
          children: ['All', 'Open', 'In Progress', 'Closed'].map((status) {
            bool isSelected = selectedFilter == status;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(status),
                selected: isSelected,
                onSelected: (bool selected) {
                  setState(() {
                    selectedFilter = status;
                    _applyFilter();
                  });
                },
                selectedColor: Colors.blue[700],
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                ),
              ),
            );
          }).toList(),
        ),
      ),

      // Area List Tiket
      Expanded(
        child: RefreshIndicator(
          onRefresh: () => _fetchTickets(query: _searchController.text),
          child: isLoading
              ? Center(child: CircularProgressIndicator())
              : filteredTickets.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(height: 100),
                        Center(child: Text("Belum ada tiket", style: TextStyle(color: Colors.grey))),
                      ],
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: filteredTickets.length,
                      itemBuilder: (context, index) {
                        final ticket = filteredTickets[index];
                        return _buildTicketCard(ticket);
                      },
                    ),
        ),
      ),
    ],
  );
}

  Widget _buildTicketCard(dynamic ticket) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TicketDetailScreen(ticketId: ticket['id']))
          );
          if (result == true) _fetchTickets();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(ticket['nomor_internal'] ?? '-', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[800])),
                  _buildStatusBadge(ticket['status'] ?? 'Open'),
                ],
              ),
              SizedBox(height: 8),
              Text(ticket['site_name'] ?? '-', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              SizedBox(height: 4),
              Text(ticket['deskripsi'] ?? '-', maxLines: 2, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(status.toUpperCase(), style: TextStyle(color: _getStatusColor(status), fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}