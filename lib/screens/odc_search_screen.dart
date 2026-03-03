import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

class OdcSearchScreen extends StatefulWidget {
  @override
  _OdcSearchScreenState createState() => _OdcSearchScreenState();
}

class _OdcSearchScreenState extends State<OdcSearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _results = [];
  bool _loading = false;
  String? _error;
  bool _hasSearched = false;

  Future<void> _handleSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
      _results = [];
      _hasSearched = true;
    });

    try {
      // Pakai ApiService yang sudah ada, otomatis kirim token
      final response = await ApiService.get('/odc-search?name=$query');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded['data'];

        setState(() {
          if (data is List) {
            _results = data;
          } else {
            _results = [];
          }
        });
      } else {
        try {
          final decoded = jsonDecode(response.body);
          setState(() {
            _error = decoded['message'] ?? 'Error ${response.statusCode}';
          });
        } catch (_) {
          setState(() {
            _error = 'Error ${response.statusCode}: ${response.body}';
          });
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _openMap(String lat, String lng) async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak dapat membuka Google Maps')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Pencarian ODC',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kolom Pencarian (Card)
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Icon(
                                  LucideIcons.search,
                                  color: Colors.grey[400],
                                  size: 20,
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText:
                                        'Masukkan nama ODC (contoh: ODC-CJR)',
                                    hintStyle: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 14,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  onSubmitted: (_) => _handleSearch(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _loading ? null : _handleSearch,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[400],
                          elevation: 0,
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _loading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Cari',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Error State
              if (_error != null)
                Container(
                  margin: EdgeInsets.only(bottom: 24),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.alertCircle,
                        color: Colors.red[600],
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(color: Colors.red[600]),
                        ),
                      ),
                    ],
                  ),
                ),

              // Hasil Pencarian
              if (_hasSearched &&
                  !_loading &&
                  _error == null &&
                  _results.isEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            LucideIcons.search,
                            color: Colors.grey[400],
                            size: 32,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Data ODC tidak ditemukan.',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_results.isNotEmpty)
                GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width > 600
                        ? 2
                        : 1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 280,
                  ),
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final item = _results[index];
                    return Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[200]!),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header: Icon + Status
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    LucideIcons.server,
                                    color: Colors.blue[600],
                                    size: 24,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'ACTIVE',
                                    style: TextStyle(
                                      color: Colors.green[800],
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),

                            // Konten Utama
                            Text(
                              item['odc_name']?.toString() ?? 'Unknown ODC',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              item['odc_spec']?.toString() ??
                                  'No spec available',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 16),

                            // Separator + Lokasi + Action Button
                            Divider(color: Colors.grey[200], height: 1),
                            SizedBox(height: 16),

                            Row(
                              children: [
                                Icon(
                                  LucideIcons.mapPin,
                                  size: 16,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${item['latitude'] ?? '-'}, ${item['longitude'] ?? '-'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'monospace',
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),

                            // Tombol Buka Map
                            SizedBox(
                              width: double.infinity,
                              child: TextButton(
                                onPressed: () {
                                  if (item['latitude'] != null &&
                                      item['longitude'] != null) {
                                    _openMap(
                                      item['latitude'].toString(),
                                      item['longitude'].toString(),
                                    );
                                  }
                                },
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.grey[50],
                                  foregroundColor: Colors.blue[600],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(color: Colors.grey[200]!),
                                  ),
                                ),
                                child: Text(
                                  'Buka di Google Maps',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
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
            ],
          ),
        ),
      ),
    );
  }
}
