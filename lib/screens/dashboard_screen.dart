import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import 'ticket_detail_screen.dart'; // Buka komen ini nanti kalau lu udah punya halaman detail tiket

class DashboardScreen extends StatefulWidget {
  final Function(String)? onNavigateToTickets;
  const DashboardScreen({Key? key, this.onNavigateToTickets}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic> stats = {
    'total': 0,
    'open': 0,
    'in_progress': 0,
    'closed': 0,
  };
  List<dynamic> recentTickets = [];
  String userName = '';
  String userRole = '';
  bool isLoading = true;
  String statusAbsen = 'loading'; 

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
    _loadUserData();
    _fetchDashboardData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('name') ?? 'User';
      userRole = prefs.getString('role') ?? 'teknisi';
    });
  }

  Future<void> _fetchDashboardData() async {
    if (!mounted) return; 
    setState(() => isLoading = true);

    try {
      final statsResponse = await ApiService.get('/dashboard/stats');
      final ticketsResponse = await ApiService.get('/tickets?per_page=5');
      final absenResponse = await ApiService.get('/absen-status'); 

      if (mounted) {
        setState(() {
          if (absenResponse.statusCode == 200) {
            statusAbsen = jsonDecode(absenResponse.body)['status'];
          } else {
            statusAbsen = 'error';
          }

          if (statsResponse.statusCode == 200 && ticketsResponse.statusCode == 200) {
            stats = jsonDecode(statsResponse.body)['data'];
            recentTickets = jsonDecode(ticketsResponse.body)['data']['data'] ?? [];
          }
          
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetch dashboard: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
          statusAbsen = 'error';
        });
      }
    }
  }

  Color _getStatusColor() {
    switch (statusAbsen) {
      case 'sudah_masuk': return Colors.green[500]!;
      case 'belum_absen': return Colors.red[500]!;
      case 'sudah_pulang': return Colors.grey[500]!;
      default: return Colors.orange[500]!; 
    }
  }

  String _getStatusText() {
    switch (statusAbsen) {
      case 'sudah_masuk': return "SEDANG SHIFT";
      case 'belum_absen': return "BELUM ABSEN";
      case 'sudah_pulang': return "SHIFT SELESAI";
      default: return "MEMUAT STATUS...";
    }
  }

  String calculateDuration(String? start, String? end, String status) {
    if (start == null) return "-";
    DateTime startTime = DateTime.parse(start).toLocal();
    DateTime endTime;

    if (status == 'Closed' && end != null) {
      endTime = DateTime.parse(end).toLocal();
    } else if (status == 'Closed' && end == null) {
      return "Data Error";
    } else {
      endTime = DateTime.now();
    }

    Duration diff = endTime.difference(startTime);
    int hours = diff.inHours;
    int minutes = diff.inMinutes.remainder(60);
    return hours > 0 ? '${hours}j ${minutes}m' : '${minutes}m';
  }

  // JURUS MUNCULIN POPUP NOTIF DARI BAWAH (SEKARANG UDAH DINAMIS BOS!)
  void _showNotificationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6, 
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.bellRing, color: Colors.blue[700]),
                        const SizedBox(width: 10),
                        const Text("Notifikasi Tiket", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1),
              
              Expanded(
                child: recentTickets.isEmpty 
                  ? const Center(child: Text("Belum ada pergerakan tiket Bos!", style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(10),
                      itemCount: recentTickets.length,
                      itemBuilder: (context, index) {
                        final ticket = recentTickets[index];
                        bool isClosed = ticket['status'] == 'Closed';
                        bool isOpen = ticket['status'] == 'Open';

                        // Set Judul dan Ikon tergantung status tiket
                        String titleNotif = isOpen ? "🚨 Tiket Baru Masuk!" : (isClosed ? "✅ Tiket Selesai" : "🛠️ Tiket Diproses");

                        return _buildNotifItem(
                          title: titleNotif,
                          body: "Tiket ${ticket['nomor_internal']} (${ticket['site_name']}) statusnya sekarang: ${ticket['status']}",
                          time: DateFormat('dd MMM HH:mm').format(DateTime.parse(ticket['updated_at'] ?? ticket['created_at']).toLocal()),
                          isUnread: !isClosed, 
                          onTap: () {
                            Navigator.pop(context); // 1. Tutup laci notif
                            
                            // 2. Terbang ke halaman Detail Tiket!
                            // PERHATIAN: Ganti 'TicketDetailScreen' sama nama Class halaman lu!
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TicketDetailScreen(
                                  // Arahin ID tiketnya biar halaman detail tau mau nampilin tiket mana
                                  ticketId: ticket['id'], 
                                ),
                              ),
                            );
                          }
                        );
                      },
                    ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildNotifItem({required String title, required String body, required String time, required bool isUnread, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isUnread ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isUnread ? Colors.blue.shade200 : Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: onTap, 
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isUnread ? Colors.blue.shade100 : Colors.grey.shade100,
          child: Icon(isUnread ? LucideIcons.bell : LucideIcons.checkCircle, color: isUnread ? Colors.blue.shade700 : Colors.grey.shade600, size: 20),
        ),
        title: Text(title, style: TextStyle(fontWeight: isUnread ? FontWeight.bold : FontWeight.w600, fontSize: 13, color: Colors.grey[800])),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(body, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ),
        trailing: Text(time, style: TextStyle(fontSize: 10, color: Colors.grey[400], fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildStatCard(String title, int count, List<Color> gradientColors, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: gradientColors[0].withOpacity(0.3), blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Stack(
        children: [
          Positioned(right: -15, bottom: -15, child: Transform.rotate(angle: 0.2, child: Icon(icon, size: 80, color: Colors.white.withOpacity(0.2)))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w500)),
              Text(isLoading ? "..." : count.toString(), style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
              Row(
                children: [
                  Text("Detail", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
                  SizedBox(width: 4),
                  Icon(LucideIcons.arrowRight, size: 12, color: Colors.white.withOpacity(0.8)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String today = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now());

    // NGITUNG ADA BERAPA TIKET YANG BELUM CLOSED BUAT ANGKA MERAH DI LONCENG
    int unreadCount = recentTickets.where((ticket) => ticket['status'] != 'Closed').length;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Dashboard Overview', style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(LucideIcons.bell, color: Colors.grey[800]),
                onPressed: _showNotificationSheet, 
              ),
              if (unreadCount > 0) 
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text(
                      unreadCount.toString(), 
                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchDashboardData,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.calendar, size: 16, color: Colors.blue[500]),
                  SizedBox(width: 8),
                  Text(today, style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
              SizedBox(height: 12),
              
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusAbsen == 'belum_absen' ? Colors.red[200]! : Colors.grey[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: _getStatusColor(), shape: BoxShape.circle),
                    ),
                    SizedBox(width: 8),
                    Text("${_getStatusText()} • ${userRole.toUpperCase()}", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                  ],
                ),
              ),
              SizedBox(height: 24),

              GridView.count(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  GestureDetector(onTap: () => widget.onNavigateToTickets?.call('All'), child: _buildStatCard('Total Tiket', stats['total'], [Colors.blue[600]!, Colors.blue[800]!], LucideIcons.ticket)),
                  GestureDetector(onTap: () => widget.onNavigateToTickets?.call('Open'), child: _buildStatCard('Open (Baru)', stats['open'], [Colors.red[500]!, Colors.red[700]!], LucideIcons.alertCircle)),
                  GestureDetector(onTap: () => widget.onNavigateToTickets?.call('In Progress'), child: _buildStatCard('In Progress', stats['in_progress'], [Colors.orange[400]!, Colors.orange[600]!], LucideIcons.clock)),
                  GestureDetector(onTap: () => widget.onNavigateToTickets?.call('Closed'), child: _buildStatCard('Selesai', stats['closed'], [Colors.teal[500]!, Colors.teal[700]!], LucideIcons.checkCircle)),
                ],
              ),
              SizedBox(height: 24),

              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[100]!)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(padding: EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)), child: Icon(LucideIcons.activity, size: 16, color: Colors.blue[600])),
                        SizedBox(width: 8),
                        Text("Statistik Penanganan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                      ],
                    ),
                    SizedBox(height: 24),
                    SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: (stats['total'] == 0 ? 10 : stats['total']).toDouble() + 5,
                          barTouchData: BarTouchData(enabled: false),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  switch (value.toInt()) {
                                    case 0: return Text('Open', style: TextStyle(fontSize: 10, color: Colors.grey[500]));
                                    case 1: return Text('Proses', style: TextStyle(fontSize: 10, color: Colors.grey[500]));
                                    case 2: return Text('Selesai', style: TextStyle(fontSize: 10, color: Colors.grey[500]));
                                    default: return Text('');
                                  }
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          barGroups: [
                            BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: stats['open'].toDouble(), color: Colors.red[500], width: 40, borderRadius: BorderRadius.vertical(top: Radius.circular(6)))]),
                            BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: stats['in_progress'].toDouble(), color: Colors.orange[500], width: 40, borderRadius: BorderRadius.vertical(top: Radius.circular(6)))]),
                            BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: stats['closed'].toDouble(), color: Colors.teal[500], width: 40, borderRadius: BorderRadius.vertical(top: Radius.circular(6)))]),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[100]!)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Tiket Terbaru & Durasi", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                    SizedBox(height: 16),
                    isLoading
                        ? Center(child: CircularProgressIndicator())
                        : recentTickets.isEmpty
                        ? Center(child: Text("Belum ada tiket terbaru.", style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)))
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: recentTickets.length,
                            itemBuilder: (context, index) {
                              final ticket = recentTickets[index];
                              bool isOpen = ticket['status'] == 'Open';
                              bool isClosed = ticket['status'] == 'Closed';

                              return Container(
                                margin: EdgeInsets.only(bottom: 12),
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(border: Border.all(color: Colors.grey[200]!), borderRadius: BorderRadius.circular(12), color: Colors.white),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(ticket['nomor_internal'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[800])),
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(4)),
                                          child: Text("${isClosed ? 'TTR:' : 'Dur:'} ${calculateDuration(ticket['created_at'], ticket['closed_at'], ticket['status'])}", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue[700], fontStyle: FontStyle.italic)),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(LucideIcons.mapPin, size: 12, color: Colors.grey[500]),
                                        SizedBox(width: 4),
                                        Expanded(child: Text(ticket['site_name'] ?? '-', style: TextStyle(fontSize: 11, color: Colors.grey[500]), overflow: TextOverflow.ellipsis)),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(color: isOpen ? Colors.red[50] : (isClosed ? Colors.green[50] : Colors.orange[50]), borderRadius: BorderRadius.circular(10)),
                                          child: Text(ticket['status'].toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isOpen ? Colors.red[600] : (isClosed ? Colors.green[600] : Colors.orange[600]))),
                                        ),
                                        Text("Dibuat: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(ticket['created_at']).toLocal())}", style: TextStyle(fontSize: 9, color: Colors.grey[400], fontStyle: FontStyle.italic)),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}