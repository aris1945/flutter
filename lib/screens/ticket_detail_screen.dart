import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:gal/gal.dart';
import 'package:dio/dio.dart';
import 'dart:typed_data';
import '../services/api_service.dart';
import 'update_worklog_screen.dart';

class TicketDetailScreen extends StatefulWidget {
  final int ticketId;

  TicketDetailScreen({required this.ticketId});

  @override
  _TicketDetailScreenState createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  Map<String, dynamic>? ticket;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTicketDetail();
  }

  Future<void> _fetchTicketDetail() async {
    setState(() => isLoading = true);
    try {
      final response = await ApiService.get('/tickets/${widget.ticketId}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            ticket = data['data'];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error fetch detail: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open': return Colors.red;
      case 'closed': return Colors.green;
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Detail Tiket', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black87),
        elevation: 1,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ticket == null
          ? Center(child: Text("Data tidak ditemukan"))
          : RefreshIndicator(
              onRefresh: _fetchTicketDetail,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(ticket!['nomor_internal'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[800])),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: _getStatusColor(ticket!['status']).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                child: Text(ticket!['status'].toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _getStatusColor(ticket!['status']))),
                              ),
                            ],
                          ),
                          Divider(height: 24, color: Colors.grey[200]),
                          _buildInfoRow(LucideIcons.mapPin, "Site", "${ticket!['site_id']} - ${ticket!['site_name']}"),
                          SizedBox(height: 8),
                          _buildInfoRow(LucideIcons.layers, "Unit", ticket!['unit'] ?? '-'),
                          SizedBox(height: 8),
                          _buildInfoRow(LucideIcons.user, "Petugas", ticket!['petugas'] ?? '-'),
                          SizedBox(height: 8),
                          _buildInfoRow(LucideIcons.alignLeft, "Deskripsi Awal", ticket!['deskripsi'] ?? '-'),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    Text("Riwayat Penanganan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                    SizedBox(height: 12),
                    ticket!['logs'] == null || ticket!['logs'].isEmpty
                        ? Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Center(child: Text("Belum ada riwayat penanganan.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))))
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: ticket!['logs'].length,
                            itemBuilder: (context, index) {
                              final log = ticket!['logs'][index];
                              final logDate = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(log['created_at']).toLocal());
                              return Container(
                                margin: EdgeInsets.only(bottom: 12),
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue[100]!)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(log['user']?['name'] ?? 'System', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[800])),
                                        Text(logDate, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    Text("Status diubah ke: ${log['status']}", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue[600])),
                                    SizedBox(height: 4),
                                    Text(log['deskripsi'] ?? '-', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                                    if (log['image_path'] != null) ...[
                                      SizedBox(height: 12),
                                      GestureDetector(
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (_) => Dialog(
                                              backgroundColor: Colors.transparent,
                                              insetPadding: EdgeInsets.all(10),
                                              child: Stack(
                                                children: [
                                                  InteractiveViewer(
                                                    child: Image.network("${ApiService.hostUrl}/${log['image_path']}", fit: BoxFit.contain),
                                                  ),
                                                  Positioned(
                                                    top: 0, right: 0,
                                                    child: SafeArea(
                                                      child: Row(
                                                        children: [
                                                          IconButton(icon: Icon(Icons.download, color: Colors.white, size: 30), onPressed: () async {
  try {
    String url = "${ApiService.hostUrl}/${log['image_path']}";
    var response = await Dio().get(url, options: Options(responseType: ResponseType.bytes));

    // Simpan sementara ke file atau langsung pake bytes
    final bytes = Uint8List.fromList(response.data);
    await Gal.putImageBytes(bytes); // Cuma satu baris!

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Berhasil disimpan!')));
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
  }
},),
                                                          IconButton(icon: Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.pop(context)),
                                                        ],
                                                      ),
                                                    ),
                                                  )
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network("${ApiService.hostUrl}/${log['image_path']}", height: 150, width: double.infinity, fit: BoxFit.cover),
                                        ),
                                      )
                                    ]
                                  ],
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
      floatingActionButton: ticket != null && ticket!['status'] != 'Closed'
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => UpdateWorklogScreen(ticket: ticket!)));
                if (result == true) _fetchTicketDetail();
              },
              backgroundColor: Colors.blue[700],
              icon: Icon(LucideIcons.camera, color: Colors.white, size: 20),
              label: Text("Worklog", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[500]),
        SizedBox(width: 8),
        SizedBox(width: 100, child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13))),
        Expanded(child: Text(value, style: TextStyle(color: Colors.grey[800], fontSize: 13, fontWeight: FontWeight.w500))),
      ],
    );
  }
}