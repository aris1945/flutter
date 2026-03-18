import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons/lucide_icons.dart';

class IboosterScreen extends StatefulWidget {
  const IboosterScreen({super.key});

  @override
  _IboosterScreenState createState() => _IboosterScreenState();
}

class _IboosterScreenState extends State<IboosterScreen> {
  final TextEditingController _inetController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  // Penampung data dari API
  String _kesimpulan = '';
  List<dynamic> _resultData = [];

  Future<void> _cekIbooster() async {
    final inet = _inetController.text.trim();
    if (inet.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Isi nomer internetnya dulu Bos!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _kesimpulan = '';
      _resultData = [];
    });

    // Rangkai URL sesuai skrip GAS lu
    final url = Uri.parse(
      "https://lensa.tacc.id/api/ukur_ibooster?inet=$inet&nik=987632&nama=bang%20jono",
    );

    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization":
              "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2xlbnNhLnRhY2MuaWQvYXBpL2xvZ2luIiwiaWF0IjoxNzM2MDk4NjY5LCJuYmYiOjE3MzYwOTg2NjksImp0aSI6InhFVE92eHB0ekJURW5uMkgiLCJzdWIiOiIxIiwicHJ2IjoiMjNiZDVjODk0OWY2MDBhZGIzOWU3MDFjNDAwODcyZGI3YTU5NzZmNyJ9.V_jEi2slkrkQjxHDg8xfnBhsujP_jHAfBSmOh-yqPmo",
          "Accept-Encoding": "gzip",
          "User-Agent": "Dart/2.16 (dart:io)",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          _kesimpulan = decoded['kesimpulan'] ?? 'Tidak ada kesimpulan';
          _resultData = decoded['data'] ?? [];
        });
      } else {
        setState(
          () => _errorMessage = "Error API Bos! Status: ${response.statusCode}",
        );
      }
    } catch (e) {
      setState(() => _errorMessage = "Gagal nembak API! Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Cek i-Booster',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // PANEL INPUT
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nomor Internet / SN:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _inetController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "Contoh: 4857544366708E40",
                      prefixIcon: const Icon(
                        LucideIcons.globe,
                        color: Colors.blue,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _cekIbooster,
                      icon: _isLoading
                          ? const SizedBox()
                          : const Icon(LucideIcons.activity, size: 18),
                      label: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Ukur Jaringan',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ERROR MESSAGE
            if (_errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _errorMessage,
                  style: TextStyle(
                    color: Colors.red.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            // HASIL PENGUKURAN
            if (_kesimpulan.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // KESIMPULAN
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                LucideIcons.barChart2,
                                color: Colors.blue.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Kesimpulan',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _kesimpulan,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // LIST DATA METERAN
                    // LIST DATA METERAN (DESAIN ATAS-BAWAH BIAR ANTI GENCET!)
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _resultData.length,
                      separatorBuilder: (context, index) =>
                          Divider(height: 1, color: Colors.grey.shade200),
                      itemBuilder: (context, index) {
                        final item = _resultData[index];
                        final indexName = item['index']?.toString() ?? '-';
                        final value =
                            (item['value'] == null || item['value'] == '')
                            ? '-'
                            : item['value'].toString();

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start, // Rata kiri semua
                            children: [
                              // LABEL DI ATAS (Warna abu-abu biar elegan)
                              Text(
                                indexName.toUpperCase(),
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6), // Jarak napas tipis
                              // VALUE DI BAWAHNYA (Warna item, font tebal ala terminal)
                              Text(
                                value,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.black87,
                                  fontFamily: 'monospace',
                                ),
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
    );
  }
}
