import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/api_service.dart';

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

  // SEKARANG NANGKEP DATA BERUPA OBJEK BUKAN STRING
  Map<String, dynamic>? resultData;
  String errorMessage = '';

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
      resultData = null;
      errorMessage = '';
    });

    String formattedDate = DateFormat(
      'd MMMM',
      'id_ID',
    ).format(selectedDate).toLowerCase();
    String shiftQuery = selectedShift == 'Semua' ? '' : selectedShift;
    String endpoint =
        "/schedule?tanggal=$formattedDate&lok=$selectedLok&shift=$shiftQuery";

    try {
      final response = await ApiService.get(endpoint);
      if (!mounted) return;

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        setState(() {
          resultData = data['data']; // Nangkep JSON terstruktur dari Laravel
        });
      } else {
        setState(
          () => errorMessage = data['message'] ?? "Data nggak ketemu Bos!",
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => errorMessage = "Gagal nembak API! Error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
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
          'Jadwal Piket B2B',
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
            // PANEL FILTER
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
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
                        items: lokOptions
                            .map(
                              (String value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text(value.toUpperCase()),
                              ),
                            )
                            .toList(),
                        onChanged: (val) => setState(() => selectedLok = val!),
                      ),
                    ],
                  ),
                  const Divider(),
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
                        items: shiftOptions
                            .map(
                              (String value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => selectedShift = val!),
                      ),
                    ],
                  ),
                  const Divider(),
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

            // ERROR MESSAGE
            if (errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.alertCircle, color: Colors.red.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        errorMessage,
                        style: TextStyle(
                          color: Colors.red.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // HASIL PENCARIAN KEREN
            if (resultData != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // HEADER TANGGAL
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade800, Colors.blue.shade500],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.calendarCheck,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            resultData!['header'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // DAFTAR TEKNISI
                  if ((resultData!['teknisi'] as List).isNotEmpty)
                    _buildRoleSection(
                      'Tim Teknisi',
                      resultData!['teknisi'],
                      Colors.blue,
                    ),

                  // DAFTAR HELPDESK
                  if ((resultData!['helpdesk'] as List).isNotEmpty)
                    _buildRoleSection(
                      'Tim Helpdesk',
                      resultData!['helpdesk'],
                      Colors.orange,
                    ),

                  // KALAU KOSONG SEMUA
                  if ((resultData!['teknisi'] as List).isEmpty &&
                      (resultData!['helpdesk'] as List).isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          "Nggak ada jadwal masuk hari ini Bos!",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // JURUS PEMBUAT KARTU PER SHIFT
  Widget _buildRoleSection(
    String title,
    List<dynamic> shiftList,
    MaterialColor color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.users, color: color.shade700, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...shiftList.map((shiftData) {
          String shiftName = shiftData['shift'];
          List<dynamic> members = shiftData['members'];

          // Atur icon & warna badge sesuai nama shift
          IconData shiftIcon = LucideIcons.sun;
          Color shiftColor = Colors.orange;
          if (shiftName == 'Malam') {
            shiftIcon = LucideIcons.moon;
            shiftColor = Colors.indigo;
          } else if (shiftName == 'Pagi') {
            shiftIcon = LucideIcons.sunrise;
            shiftColor = Colors.blue;
          } else if (shiftName == 'Libur' || shiftName == 'Cuti') {
            shiftIcon = LucideIcons.bedDouble;
            shiftColor = Colors.red;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // HEADER SHIFT
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(shiftIcon, size: 18, color: shiftColor),
                          const SizedBox(width: 8),
                          Text(
                            'Shift $shiftName',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: shiftColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${members.length} Orang',
                          style: TextStyle(
                            color: shiftColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // LIST ORANGNYA
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: members.length,
                  separatorBuilder: (context, index) =>
                      Divider(height: 1, color: Colors.grey.shade100),
                  itemBuilder: (context, index) {
                    var person = members[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: color.shade50,
                        child: Text(
                          person['name'][0],
                          style: TextStyle(
                            color: color.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        person['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        'NIK: ${person['nik']}',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                          fontFamily: 'monospace',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        }).toList(),
        const SizedBox(height: 16),
      ],
    );
  }
}
