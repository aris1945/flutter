import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/api_service.dart'; // Pastiin path ApiService lu bener ya jing!
import 'package:flutter/services.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  String selectedLok = 'ijk';
  String selectedShift = 'Semua';
  DateTime selectedDate = DateTime.now();

  bool isLoading = false;
  String resultMessage = '';

  final List<String> lokOptions = ['ijk', 'mgo'];
  final List<String> shiftOptions = [
    'Semua',
    'Pagi',
    'Siang',
    'Malam',
    'Bantek',
    'Libur',
    'Cuti',
  ];

  Future<void> _fetchSchedule() async {
    setState(() {
      isLoading = true;
      resultMessage = '';
    });

    // Format tanggal ke "16 juni" biar dimengerti API Laravel/skrip lu
    String formattedDate = DateFormat(
      'd MMMM',
      'id_ID',
    ).format(selectedDate).toLowerCase();
    String shiftQuery = selectedShift == 'Semua' ? '' : selectedShift;

    // Rangkai Endpoint-nya
    String endpoint =
        "/schedule?tanggal=$formattedDate&lok=$selectedLok&shift=$shiftQuery";

    try {
      final response = await ApiService.get(endpoint);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          resultMessage = data['data']; // Output dari Laravel
        });
      } else {
        setState(
          () => resultMessage =
              "Error Server Laravel Bos! Status: ${response.statusCode}",
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(
        () => resultMessage =
            "Gagal nembak API! Cek internet atau server lu jing.\n\nError: $e",
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Jadwal Piket SA',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // PANEL FILTER PENCARIAN
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  // Dropdown Lokasi
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.mapPin,
                        color: Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Lokasi SA:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      DropdownButton<String>(
                        value: selectedLok,
                        underline: const SizedBox(),
                        items: lokOptions.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => selectedLok = val!),
                      ),
                    ],
                  ),
                  const Divider(),

                  // Dropdown Shift
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.clock,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Shift:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      DropdownButton<String>(
                        value: selectedShift,
                        underline: const SizedBox(),
                        items: shiftOptions.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => selectedShift = val!),
                      ),
                    ],
                  ),
                  const Divider(),

                  // Pilih Tanggal
                  GestureDetector(
                    onTap: () => _selectDate(context),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.calendar,
                          color: Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Tanggal:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            DateFormat(
                              'dd MMMM yyyy',
                              'id_ID',
                            ).format(selectedDate),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tombol Cari
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : _fetchSchedule,
                      icon: isLoading
                          ? const SizedBox()
                          : const Icon(LucideIcons.search, size: 18),
                      label: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Cari Jadwal',
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

            // HASIL PENCARIAN
            // HASIL PENCARIAN
            if (resultMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              LucideIcons.clipboardList,
                              color: Colors.blue.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Hasil Pencarian',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ],
                        ),
                        // TOMBOL COPY INSTAN ALA KORPORAT
                        IconButton(
                          icon: const Icon(
                            LucideIcons.copy,
                            size: 20,
                            color: Colors.blue,
                          ),
                          onPressed: () {
                            // Masukin teks ke Clipboard HP
                            Clipboard.setData(
                              ClipboardData(text: resultMessage),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Jadwal sukses dicopas Bos!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          tooltip: 'Copy Jadwal',
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    // TEKS SEKARANG BISA DIBLOK MANUAL JUGA
                    SelectableText(
                      resultMessage,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                        height: 1.5,
                      ),
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
