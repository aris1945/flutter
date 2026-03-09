import 'dart:async'; // WAJIB ADA BUAT FITUR DEBOUNCE
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

class SpbuListScreen extends StatefulWidget {
  const SpbuListScreen({super.key});

  @override
  _SpbuListScreenState createState() => _SpbuListScreenState();
}

class _SpbuListScreenState extends State<SpbuListScreen> {
  List<dynamic> spbus = [];
  bool isLoading = true;
  String searchQuery = '';

  // STATE PAGINATION ALA REACT LU
  int currentPage = 1;
  int totalPages = 1;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchSpbus(page: 1);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  // JURUS SEDOT DATA API + PAGINATION
  Future<void> _fetchSpbus({int page = 1}) async {
    setState(() => isLoading = true);
    try {
      // Rangkai URL persis kayak param axios di React lu
      String endpoint = '/spbu?page=$page&search=$searchQuery';
      final response = await ApiService.get(endpoint);

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        final metaData = decodedResponse['data']; // Nangkep object pagination

        if (mounted) {
          setState(() {
            spbus = metaData['data'] ?? [];
            currentPage = metaData['current_page'] ?? 1;
            totalPages = metaData['last_page'] ?? 1;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error fetch SPBU: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  // FITUR DEBOUNCE (Otomatis nyari setelah berhenti ngetik 500ms)
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        searchQuery = query;
      });
      _fetchSpbus(page: 1); // Pas nyari, paksa balik ke halaman 1
    });
  }

  Future<void> _openGoogleMaps(String? lat, String? long) async {
    String queryMap = '';
    if (lat != null && lat.isNotEmpty) {
      if (lat.contains(',')) {
        queryMap = lat;
      } else if (long != null && long.isNotEmpty) {
        queryMap = "$lat,$long";
      } else {
        queryMap = lat;
      }

      final Uri url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$queryMap?q=$queryMap',
      );

      try {
        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
          throw Exception('Gagal buka maps Bos!');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Koordinat kosong Bos!'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Data SPBU',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 1,
      ),
      body: Column(
        children: [
          // SEARCH BAR
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              onChanged: _onSearchChanged, // Pake fungsi debounce
              decoration: InputDecoration(
                hintText: "Cari Kode, Nama SPBU, atau Area...",
                prefixIcon: const Icon(LucideIcons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // LIST DATA SPBU
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.red),
                  )
                : spbus.isEmpty
                ? const Center(
                    child: Text(
                      "Data SPBU nggak ketemu",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => _fetchSpbus(page: currentPage),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: spbus.length,
                      itemBuilder: (context, index) {
                        final item = spbus[index];
                        final isCoco =
                            (item['tipe_spbu'] ?? '')
                                .toString()
                                .toUpperCase() ==
                            'COCO';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade100,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.red[50],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        LucideIcons.fuel,
                                        color: Colors.red[700],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['kode_spbu'] ?? '-',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.red[700],
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            item['nama_spbu'] ?? '-',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isCoco
                                            ? Colors.blue[50]
                                            : Colors.orange[50],
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        item['tipe_spbu'] ?? '-',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                          color: isCoco
                                              ? Colors.blue[700]
                                              : Colors.orange[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildInfoRow(
                                            LucideIcons.network,
                                            'IP Address',
                                            item['ip_address'],
                                          ),
                                          const SizedBox(height: 8),
                                          _buildInfoRow(
                                            LucideIcons.map,
                                            'Area / SO',
                                            "${item['area'] ?? '-'} / ${item['so'] ?? '-'}",
                                          ),
                                          const SizedBox(height: 8),
                                          _buildInfoRow(
                                            LucideIcons.navigation,
                                            'Alamat',
                                            item['alamat'],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _openGoogleMaps(
                                      item['latitude'],
                                      item['longitude'],
                                    ),
                                    icon: const Icon(
                                      LucideIcons.mapPin,
                                      size: 16,
                                    ),
                                    label: const Text(
                                      'Buka di Google Maps',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue[50],
                                      foregroundColor: Colors.blue[700],
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),

      // =========================================================
      // UI PAGINATION (PREV - HALAMAN - NEXT)
      // =========================================================
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          border: Border(top: BorderSide(color: Colors.grey[200]!)),
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // TOMBOL PREV
              ElevatedButton(
                onPressed: currentPage > 1 && !isLoading
                    ? () => _fetchSpbus(page: currentPage - 1)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Prev'),
              ),

              // INFO HALAMAN
              Text(
                'Halaman $currentPage dari $totalPages',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),

              // TOMBOL NEXT
              ElevatedButton(
                onPressed: currentPage < totalPages && !isLoading
                    ? () => _fetchSpbus(page: currentPage + 1)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, dynamic value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                (value == null || value == '') ? '-' : value.toString(),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
