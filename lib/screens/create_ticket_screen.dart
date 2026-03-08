import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Buat debugPrint
import 'package:lucide_icons/lucide_icons.dart';
import '../services/api_service.dart';

class CreateTicketScreen extends StatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool isFetchingData = true; // Tambahan buat loading awal

  // State Form
  String nomorInternal = 'Loading...';
  String unitType = 'CNOP';
  String? ticketType;
  String? selectedSa;
  String siteName = '';
  String siteId = '';

  // Controllers
  final _sysNumController = TextEditingController();
  final _descController = TextEditingController();
  final _siteSearchController = TextEditingController(); // Controller buat Autocomplete

  // State Data
  List<Map<String, dynamic>> sites = [];
  List<Map<String, dynamic>> spbu = []; // Pisahin data SPBU
  List<Map<String, dynamic>> posko = []; // Data Posko
  List<Map<String, dynamic>> technicians = [];
  List<Map<String, dynamic>> saList = []; // State buat SA
  List<Map<String, dynamic>> selectedTechnicians = [];

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  @override
  void dispose() {
    _sysNumController.dispose();
    _descController.dispose();
    _siteSearchController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    setState(() => isFetchingData = true);
    
    try {
      // 1. Tarik Nomor Tiket Internal
      final resTicket = await ApiService.get('/tickets/next-number');
      if (resTicket.statusCode == 200) {
        if (mounted) {
          setState(() {
            nomorInternal = jsonDecode(resTicket.body)['ticket_number'] ?? 'Error';
          });
        }
      }

      // 2. Tarik Data CNOP
      final resSites = await ApiService.get('/sites?per_page=10000');
      if (resSites.statusCode == 200) {
        final decoded = jsonDecode(resSites.body);
        final rawSites = (decoded['data'] is List) ? decoded['data'] : (decoded['data']['data'] ?? []);
        if (mounted) setState(() => sites = List<Map<String, dynamic>>.from(rawSites));
      }

      // 3. Tarik Data SPBU
      final resSpbu = await ApiService.get('/spbu?per_page=10000');
      if (resSpbu.statusCode == 200) {
        final decoded = jsonDecode(resSpbu.body);
        final rawSpbu = (decoded['data'] is List) ? decoded['data'] : (decoded['data']['data'] ?? []);
        if (mounted) setState(() => spbu = List<Map<String, dynamic>>.from(rawSpbu));
      }

      // 3b. Tarik Data Posko
      final resPosko = await ApiService.get('/posko?per_page=10000');
      if (resPosko.statusCode == 200) {
        final decoded = jsonDecode(resPosko.body);
        final rawPosko = (decoded['data'] is List) ? decoded['data'] : (decoded['data']['data'] ?? []);
        if (mounted) setState(() => posko = List<Map<String, dynamic>>.from(rawPosko));
      }

      // 4. Tarik Data Teknisi
      final resUsers = await ApiService.get('/users/teknisi');
      if (resUsers.statusCode == 200) {
        final rawUsers = jsonDecode(resUsers.body)['data'] as List? ?? [];
        if (mounted) setState(() => technicians = List<Map<String, dynamic>>.from(rawUsers));
      }

      // 5. Tarik Data SA (Service Area)
      final resSa = await ApiService.get('/sa');
      if (resSa.statusCode == 200) {
        final decoded = jsonDecode(resSa.body);
        final rawSa = (decoded['data'] is List) ? decoded['data'] : (decoded['data']['data'] ?? []);
        if (mounted) setState(() => saList = List<Map<String, dynamic>>.from(rawSa));
      }

    } catch (e) {
      debugPrint("Error fetch initial data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil data dari server: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isFetchingData = false);
    }
  }

  // Logic pindah tab Unit
  void _changeUnitType(String newUnit) {
    if (unitType != newUnit) {
      setState(() {
        unitType = newUnit;
        siteId = '';
        siteName = '';
        _siteSearchController.clear();
      });
    }
  }

  // --- WIDGET MULTI-SELECT TEKNISI ---
  void _showMultiSelectTechnician() async {
    final List<Map<String, dynamic>> tempSelected = List.from(selectedTechnicians);
    String searchQuery = '';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredTechs = technicians.where((tech) {
              final name = (tech['name'] ?? '').toString().toLowerCase();
              final nik = (tech['nik'] ?? '').toString().toLowerCase();
              final query = searchQuery.toLowerCase();
              return name.contains(query) || nik.contains(query);
            }).toList();

            return AlertDialog(
              title: const Text("Pilih Petugas / Teknisi", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              contentPadding: const EdgeInsets.only(top: 10),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Cari nama atau NIK...",
                          prefixIcon: const Icon(LucideIcons.search, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onChanged: (value) => setModalState(() => searchQuery = value),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: filteredTechs.isEmpty
                          ? const Center(child: Text("Teknisi tidak ditemukan", style: TextStyle(color: Colors.grey)))
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: filteredTechs.length,
                              itemBuilder: (context, index) {
                                final tech = filteredTechs[index];
                                final isChecked = tempSelected.any((t) => t['id'] == tech['id']);

                                return CheckboxListTile(
                                  title: Text(tech['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text("NIK: ${tech['nik'] ?? '-'}"),
                                  value: isChecked,
                                  activeColor: Colors.blue[700],
                                  onChanged: (bool? value) {
                                    setModalState(() {
                                      if (value == true) {
                                        tempSelected.add(tech);
                                      } else {
                                        tempSelected.removeWhere((t) => t['id'] == tech['id']);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text("Batal", style: TextStyle(color: Colors.grey)),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevButtonCustom(
                  text: "Simpan",
                  onPressed: () {
                    setState(() => selectedTechnicians = tempSelected);
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- SUBMIT FORM ---
  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate() || siteId.isEmpty || selectedTechnicians.isEmpty || selectedSa == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lengkapi form dulu Bos! (Site, SA & Teknisi wajib isi)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    // Format teknisi jadi string kayak di React
    String petugasString = selectedTechnicians.map((t) => "${t['name']} (${t['nik']})").join(', ');

    final payload = {
      'nomor_internal': nomorInternal,
      'nomor_sistem': _sysNumController.text,
      'unit': unitType,
      'jenis': ticketType,
      'sa': selectedSa,
      'site_name': siteName,
      'site_id': siteId,
      'deskripsi': _descController.text,
      'petugas': petugasString,
    };

    try {
      final response = await ApiService.post('/tickets', payload);

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tiket berhasil dibuat!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // Kembali dan trigger refresh list
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Gagal buat tiket');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
      setState(() => isLoading = false);
    }
  }

  // Custom UI Card Unit
  Widget _buildUnitCard(String title) {
    final isSelected = unitType == title;
    return InkWell(
      onTap: () => _changeUnitType(title),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.white,
          border: Border.all(color: isSelected ? Colors.blue[700]! : Colors.grey[300]!, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.blue[700] : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Buat Tiket Baru', style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 1,
      ),
      body: isFetchingData
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // --- KOTAK INFO NOMOR ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("No. Tiket Internal", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 5),
                              Text(nomorInternal, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.blue)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("No. Sistem", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 5),
                              SizedBox(
                                height: 35,
                                child: TextFormField(
                                  controller: _sysNumController,
                                  decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(horizontal: 10),
                                    border: OutlineInputBorder(),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- PILIHAN UNIT ---
                  Text("Pilih Unit", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildUnitCard('CNOP')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildUnitCard('SPBU')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildUnitCard('Posko')),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- DROPDOWN JENIS TIKET ---
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Jenis Tiket',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    value: ticketType,
                    items: ['PSB', 'Gangguan', 'Preventive', 'Lain-Lain'].map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                    onChanged: (val) => setState(() => ticketType = val),
                    validator: (val) => val == null ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),

                  // --- DROPDOWN SA (SERVICE AREA) ---
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Service Area (SA)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    value: selectedSa,
                    items: saList.map((sa) => DropdownMenuItem(value: sa['sa_code'].toString(), child: Text(sa['sa_name'].toString()))).toList(),
                    onChanged: (val) => setState(() => selectedSa = val),
                    validator: (val) => val == null ? 'Pilih SA!' : null,
                  ),
                  const SizedBox(height: 16),

                  // --- LOKASI SITE / SPBU / POSKO ---
                  Text(
                    unitType == 'SPBU' ? "Lokasi SPBU" : (unitType == 'Posko' ? "Lokasi Posko" : "Lokasi Site"),
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),

                  // Posko: input manual (tanpa autocomplete)
                  if (unitType == 'Posko')
                    TextFormField(
                      key: const ValueKey('posko_manual'),
                      initialValue: siteName,
                      decoration: InputDecoration(
                        hintText: "Ketik lokasi Posko...",
                        prefixIcon: const Icon(LucideIcons.mapPin, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      validator: (value) => (value == null || value.isEmpty) ? 'Lokasi Posko wajib diisi!' : null,
                      onChanged: (val) {
                        setState(() {
                          siteName = val;
                          siteId = val; // Untuk Posko, siteId = siteName (manual)
                        });
                      },
                    ),

                  // CNOP & SPBU: pakai Autocomplete dropdown
                  if (unitType != 'Posko')
                    Autocomplete<Map<String, dynamic>>(
                      key: ValueKey(unitType),
                      displayStringForOption: (option) => unitType == 'SPBU'
                          ? "${option['kode_spbu']} - ${option['nama_spbu']}"
                          : "${option['site_id']} - ${option['site_name']}",
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) return const Iterable<Map<String, dynamic>>.empty();
                        
                        final dataList = unitType == 'SPBU' ? spbu : sites;
                        return dataList.where((item) {
                          String searchStr = unitType == 'SPBU'
                              ? "${item['kode_spbu']} ${item['nama_spbu']}".toLowerCase()
                              : "${item['site_id']} ${item['site_name']}".toLowerCase();
                          return searchStr.contains(textEditingValue.text.toLowerCase());
                        });
                      },
                      onSelected: (selection) {
                        setState(() {
                          if (unitType == 'SPBU') {
                            siteId = selection['kode_spbu'].toString();
                            siteName = selection['nama_spbu'] ?? selection['nama'] ?? '';
                          } else {
                            siteId = selection['site_id'].toString();
                            siteName = selection['site_name'].toString();
                          }
                        });
                        FocusScope.of(context).unfocus();
                      },
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        if (controller.text.isEmpty && siteId.isNotEmpty) {
                          controller.text = "$siteId - $siteName";
                        }
                        
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            hintText: unitType == 'SPBU' ? "Ketik nama/kode SPBU..." : "Ketik nama/ID site...",
                            prefixIcon: const Icon(LucideIcons.mapPin, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            suffixIcon: siteId.isNotEmpty 
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    controller.clear();
                                    setState(() {
                                      siteId = '';
                                      siteName = '';
                                    });
                                  },
                                ) 
                              : null,
                          ),
                          validator: (value) => siteId.isEmpty ? 'Pilih lokasi dari daftar dropdown!' : null,
                          onChanged: (val) {
                            if (siteId.isNotEmpty) setState(() { siteId = ''; siteName = ''; });
                          },
                        );
                    },
                  ),
                  const SizedBox(height: 16),

                  // --- CHIPS MULTI-SELECT TEKNISI ---
                  Text("Petugas / Teknisi", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _showMultiSelectTechnician,
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 50),
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: selectedTechnicians.isEmpty ? 14 : 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: selectedTechnicians.isEmpty
                                ? Text("Pilih petugas...", style: TextStyle(color: Colors.grey[600]))
                                : Wrap(
                                    spacing: 6.0,
                                    runSpacing: 4.0,
                                    children: selectedTechnicians.map((t) {
                                      return Chip(
                                        label: Text(t['name'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        backgroundColor: Colors.blue[50],
                                        deleteIconColor: Colors.red[400],
                                        onDeleted: () {
                                          setState(() => selectedTechnicians.removeWhere((item) => item['id'] == t['id']));
                                        },
                                      );
                                    }).toList(),
                                  ),
                          ),
                          const Icon(LucideIcons.chevronDown, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- DESKRIPSI ---
                  TextFormField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Deskripsi Masalah / Pekerjaan',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 30),

                  // --- TOMBOL SUBMIT ---
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : _submitTicket,
                      icon: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(LucideIcons.send),
                      label: Text(isLoading ? 'Mengirim...' : 'Buat Tiket', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}

// Widget Bantuan Buat Tombol Simpan di Modal
class ElevButtonCustom extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  
  const ElevButtonCustom({super.key, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700]),
      onPressed: onPressed,
      child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }
}