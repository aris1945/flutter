import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/api_service.dart';

class AbsensiScreen extends StatefulWidget {
  @override
  _AbsensiScreenState createState() => _AbsensiScreenState();
}

class _AbsensiScreenState extends State<AbsensiScreen> {
  final TextEditingController _employeeIdController = TextEditingController();

  Map<String, dynamic>? _reportData;
  bool _loading = false;
  String? _error;

  Future<void> _handleSearch() async {
    final employeeId = _employeeIdController.text.trim();
    if (employeeId.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
      _reportData = null;
    });

    try {
      final response = await ApiService.get('/absensi?employee_id=$employeeId');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          _reportData = decoded;
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
        _error = 'Gagal mengambil data absensi: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // Widget badge keterangan
  Widget _buildKeteranganBadge(String? keterangan) {
    if (keterangan == 'Mobile') {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.smartphone, size: 14, color: Colors.green[700]),
            SizedBox(width: 4),
            Text(
              'Mobile',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
          ],
        ),
      );
    } else if (keterangan == 'Cuti') {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.coffee, size: 14, color: Colors.orange[700]),
            SizedBox(width: 4),
            Text(
              'Cuti',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.orange[700],
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          keterangan ?? '-',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _employeeIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            Icon(LucideIcons.calendar, color: Colors.blue[600], size: 22),
            SizedBox(width: 8),
            Text(
              'Laporan Absensi',
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
              // Form Input NIK
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
                                  LucideIcons.user,
                                  color: Colors.grey[400],
                                  size: 20,
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _employeeIdController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: 'Masukkan NIK / Employee ID',
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
                      ElevatedButton.icon(
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
                          _loading ? 'Memuat...' : 'Cek',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[400],
                          elevation: 0,
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
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

              // Hasil Laporan
              if (_reportData != null) ...[
                // Header Laporan
                Card(
                  elevation: 0,
                  color: Colors.blue[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Periode Laporan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              _reportData!['periode']?.toString() ?? '-',
                              style: TextStyle(
                                color: Colors.blue[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'TOTAL ABSEN',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[500],
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                _reportData!['total_data']?.toString() ?? '0',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Tabel Data Absensi
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(12),
                    ),
                    side: BorderSide(color: Colors.grey[200]!),
                  ),
                  margin: EdgeInsets.zero,
                  child: _buildDataTable(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataTable() {
    final dataList = _reportData!['data'];
    if (dataList == null || dataList is! List || dataList.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text(
            'Tidak ada data absensi pada periode ini.',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
        headingTextStyle: TextStyle(
          color: Colors.grey[600],
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
        dataTextStyle: TextStyle(color: Colors.grey[700], fontSize: 13),
        columns: [
          DataColumn(label: Text('NO')),
          DataColumn(label: Text('TANGGAL')),
          DataColumn(label: Text('JAM MASUK')),
          DataColumn(label: Text('PLATFORM')),
        ],
        rows: List.generate(dataList.length, (index) {
          final item = dataList[index];
          return DataRow(
            cells: [
              DataCell(
                Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: Colors.grey[400],
                  ),
                ),
              ),
              DataCell(
                Text(
                  item['present_date']?.toString() ?? '-',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              DataCell(
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.clock,
                        size: 14,
                        color: Colors.blue[600],
                      ),
                      SizedBox(width: 4),
                      Text(
                        item['in_dtm']?.toString() ?? '-',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: Colors.blue[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              DataCell(_buildKeteranganBadge(item['keterangan']?.toString())),
            ],
          );
        }),
      ),
    );
  }
}
