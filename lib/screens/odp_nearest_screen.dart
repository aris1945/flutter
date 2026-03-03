import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';

class OdpNearestScreen extends StatefulWidget {
  @override
  _OdpNearestScreenState createState() => _OdpNearestScreenState();
}

class _OdpNearestScreenState extends State<OdpNearestScreen> {
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();

  List<dynamic> _results = [];
  bool _loading = false;
  bool _gpsLoading = false;
  String? _error;
  bool _hasSearched = false;
  int _resultCount = 0;

  // Ambil lokasi GPS saat ini
  Future<void> _handleGetLocation() async {
    setState(() {
      _gpsLoading = true;
      _error = null;
    });

    try {
      // Cek izin lokasi
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _error = 'Izin lokasi ditolak.';
            _gpsLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _error = 'Izin lokasi ditolak permanen. Aktifkan di pengaturan.';
          _gpsLoading = false;
        });
        return;
      }

      // Ambil posisi
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latController.text = position.latitude.toString();
        _lngController.text = position.longitude.toString();
        _gpsLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal mengambil lokasi: $e';
        _gpsLoading = false;
      });
    }
  }

  // Cari ODP terdekat
  Future<void> _handleSearch() async {
    final lat = _latController.text.trim();
    final lng = _lngController.text.trim();
    if (lat.isEmpty || lng.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
      _results = [];
      _hasSearched = true;
    });

    try {
      final response = await ApiService.get('/odp-nearest?lat=$lat&long=$lng');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          _results = decoded['data'] ?? [];
          _resultCount = decoded['count'] ?? 0;
        });
      } else {
        try {
          final decoded = jsonDecode(response.body);
          setState(() {
            _error = decoded['message'] ?? 'Error ${response.statusCode}';
          });
        } catch (_) {
          setState(() {
            _error = 'Error ${response.statusCode}';
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
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            Icon(LucideIcons.mapPin, color: Colors.blue[600], size: 22),
            SizedBox(width: 8),
            Text(
              'ODP Terdekat (250m)',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
              // Form Input Koordinat
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Input Latitude & Longitude
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Latitude',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(height: 6),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: TextField(
                                    controller: _latController,
                                    keyboardType:
                                        TextInputType.numberWithOptions(
                                          decimal: true,
                                          signed: true,
                                        ),
                                    decoration: InputDecoration(
                                      hintText: '-7.12345',
                                      hintStyle: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 14,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Longitude',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(height: 6),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: TextField(
                                    controller: _lngController,
                                    keyboardType:
                                        TextInputType.numberWithOptions(
                                          decimal: true,
                                          signed: true,
                                        ),
                                    decoration: InputDecoration(
                                      hintText: '112.12345',
                                      hintStyle: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 14,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // Tombol GPS + Cari
                      Row(
                        children: [
                          // Tombol Ambil Lokasi
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: (_gpsLoading || _loading)
                                  ? null
                                  : _handleGetLocation,
                              icon: _gpsLoading
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(LucideIcons.navigation, size: 18),
                              label: Text(
                                _gpsLoading ? 'Mencari...' : 'Ambil Lokasi',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[600],
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey[400],
                                elevation: 0,
                                padding: EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          // Tombol Cari ODP
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _loading ? null : _handleSearch,
                              icon: _loading
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(LucideIcons.search, size: 18),
                              label: Text(
                                _loading ? 'Memindai...' : 'Cari ODP',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[600],
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey[400],
                                elevation: 0,
                                padding: EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
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
                    border: Border.all(color: Colors.red[200]!),
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

              // Empty State
              if (_hasSearched &&
                  !_loading &&
                  _error == null &&
                  _results.isEmpty)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.mapPin,
                        color: Colors.grey[300],
                        size: 48,
                      ),
                      SizedBox(height: 12),
                      Text(
                        '⚠️ Tidak ada ODP dalam radius 250m.',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Coba geser lokasi sedikit atau cek koordinat Anda.',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ),
                ),

              // Hasil Pencarian (List of Cards)
              if (_results.isNotEmpty)
                ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _results[index];
                    final distance = item['distance'];
                    final distanceText = distance != null
                        ? '${(distance * 1000).toStringAsFixed(1)} m'
                        : '-';

                    return Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[200]!),
                      ),
                      child: Stack(
                        children: [
                          // Badge Jarak
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(12),
                                  bottomLeft: Radius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.ruler,
                                    size: 12,
                                    color: Colors.blue[700],
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    distanceText,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Konten utama
                          Padding(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Nama ODP
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.orange[50],
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        LucideIcons.home,
                                        color: Colors.orange[600],
                                        size: 20,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        item['odp_name']?.toString() ??
                                            'Unknown ODP',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),

                                // Koordinat
                                Row(
                                  children: [
                                    Icon(
                                      LucideIcons.mapPin,
                                      size: 16,
                                      color: Colors.grey[400],
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      '${item['lat'] ?? '-'}, ${item['lng'] ?? '-'}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'monospace',
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),

                                // Tombol Buka Maps
                                SizedBox(
                                  width: double.infinity,
                                  child: TextButton(
                                    onPressed: () {
                                      if (item['lat'] != null &&
                                          item['lng'] != null) {
                                        _openMap(
                                          item['lat'].toString(),
                                          item['lng'].toString(),
                                        );
                                      }
                                    },
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.grey[50],
                                      foregroundColor: Colors.blue[600],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        side: BorderSide(
                                          color: Colors.grey[200]!,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      'Buka di Maps',
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
                        ],
                      ),
                    );
                  },
                ),

              // Footer Summary
              if (_hasSearched && !_loading)
                Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Center(
                    child: Text(
                      'Total ditemukan: $_resultCount ODP (Max radius 250m)',
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
