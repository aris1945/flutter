import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Buat debugPrint
import 'package:lucide_icons/lucide_icons.dart';
import '../services/api_service.dart';

class CreateTicketScreen extends StatefulWidget {
  // Fix Warning 1: Tambahin super.key
  const CreateTicketScreen({super.key});

  @override
  // Fix Warning 2: Ganti private return jadi public State
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  String unitType = 'CNOP';
  int? selectedSiteId;
  String? ticketType;
  List<Map<String, dynamic>> selectedTechnicians = [];

  final _sysNumController = TextEditingController();
  final _saController = TextEditingController();
  final _descController = TextEditingController();

  // Fix Error 1: Ganti dynamic jadi Map biar spesifik dan gak error
  List<Map<String, dynamic>> sites = [];
  List<Map<String, dynamic>> technicians = [];

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    // 1. TARIK DATA SITE / SPBU SECARA DINAMIS
    try {
      // Logic URL: Kalau SPBU tembak '/spbu', kalau CNOP tembak '/sites'
      String endpointSite = unitType == 'SPBU' ? '/spbu' : '/sites';

      final resSites = await ApiService.get(endpointSite);

      if (resSites.statusCode == 200) {
        final decoded = jsonDecode(resSites.body);

        final rawSites = (decoded['data'] is List)
            ? decoded['data']
            : (decoded['data']['data'] ?? []);

        if (mounted) {
          setState(() {
            sites = (rawSites as List)
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetch sites/spbu: $e");
    }

    // 2. TARIK DATA TEKNISI SENDIRIAN
    try {
      final resUsers = await ApiService.get('/users/teknisi');
      if (resUsers.statusCode == 200) {
        final rawUsers = jsonDecode(resUsers.body)['data'] as List? ?? [];

        if (mounted) {
          setState(() {
            technicians = rawUsers
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetch teknisi: $e");
    }
  }

  void _showMultiSelectTechnician() async {
    final List<Map<String, dynamic>> tempSelected = List.from(
      selectedTechnicians,
    );
    String searchQuery = '';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredTechs = technicians.where((tech) {
              final name = (tech['name'] ?? '').toString().toLowerCase();
              final nik = (tech['nik'] ?? '')
                  .toString()
                  .toLowerCase(); // Tambahin NIK buat dicari
              final query = searchQuery.toLowerCase();
              return name.contains(query) || nik.contains(query);
            }).toList();

            return AlertDialog(
              title: const Text(
                "Cari Teknisi",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: "Cari nama atau NIK...",
                        prefixIcon: const Icon(LucideIcons.search, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      onChanged: (value) {
                        setModalState(() {
                          searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: filteredTechs.isEmpty
                          ? const Center(
                              child: Text(
                                "Teknisi tidak ditemukan",
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: filteredTechs.length,
                              itemBuilder: (context, index) {
                                final tech = filteredTechs[index];
                                final isChecked = tempSelected.any(
                                  (t) => t['id'] == tech['id'],
                                );

                                return CheckboxListTile(
                                  title: Text(
                                    tech['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "NIK: ${tech['nik'] ?? '-'}",
                                  ), // NIK NONGOL DI SINI
                                  value: isChecked,
                                  activeColor: Colors.blue[700],
                                  onChanged: (bool? value) {
                                    setModalState(() {
                                      if (value == true) {
                                        tempSelected.add(tech);
                                      } else {
                                        tempSelected.removeWhere(
                                          (t) => t['id'] == tech['id'],
                                        );
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
                  child: const Text(
                    "Batal",
                    style: TextStyle(color: Colors.grey),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                  ),
                  child: const Text(
                    "Simpan",
                    style: TextStyle(color: Colors.white),
                  ),
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

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate() ||
        selectedSiteId == null ||
        selectedTechnicians.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lengkapi form dulu Bos! (Site & Teknisi wajib isi)'),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    final payload = {
      'unit': unitType,
      'site_id': selectedSiteId,
      'ticket_type': ticketType,
      'system_number': _sysNumController.text,
      'service_area': _saController.text,
      'description': _descController.text,
      'technicians': selectedTechnicians.map((t) => t['id']).toList(),
    };

    try {
      final response = await ApiService.post('/tickets', payload);

      // Fix Warning 5: Cek mounted setelah await sebelum pakai context
      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Tiket berhasil dibuat!')));
        Navigator.pop(context, true);
      } else {
        throw Exception('Gagal buat tiket');
      }
    } catch (e) {
      if (!mounted) return; // Cek mounted juga di catch
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => isLoading = false);
    }
  }

  // Fix Error 6: Widget custom buat gantiin RadioListTile yang deprecated
  Widget _buildUnitCard(String title) {
    final isSelected = unitType == title;
    return InkWell(
      onTap: () {
        setState(() {
          unitType = title;
          selectedSiteId = null;
          _fetchInitialData();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.blue[700]! : Colors.grey[300]!,
          ),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Buat Tiket Baru',
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    "Pilih Unit",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildUnitCard('CNOP')),
                      const SizedBox(width: 16),
                      Expanded(child: _buildUnitCard('SPBU')),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Text(
                    "Cari Site / Lokasi",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Autocomplete<Map<String, dynamic>>(
                    // 1. GANTI DISPLAY STRING (Biar pas diklik, masuk ke kotaknya bener)
                    displayStringForOption: (option) {
                      if (unitType == 'SPBU') {
                        return "${option['kode_spbu']} - ${option['nama_spbu']}";
                      } else {
                        return "${option['site_id']} - ${option['site_name']}";
                      }
                    },

                    // 2. GANTI LOGIC SEARCH-NYA (Biar bisa ngetik kode/nama SPBU)
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty)
                        return const Iterable<Map<String, dynamic>>.empty();

                      return sites.where((site) {
                        String searchStr = "";
                        if (unitType == 'SPBU') {
                          searchStr =
                              "${site['kode_spbu']} ${site['nama_spbu']}"
                                  .toLowerCase();
                        } else {
                          searchStr = "${site['site_id']} ${site['site_name']}"
                              .toLowerCase();
                        }
                        return searchStr.contains(
                          textEditingValue.text.toLowerCase(),
                        );
                      });
                    },

                    onSelected: (selection) => selectedSiteId = selection['id'],

                    fieldViewBuilder:
                        (context, controller, focusNode, onFieldSubmitted) {
                          return TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              // Biar hint text-nya ngikutin unit yang dipilih
                              hintText: unitType == 'SPBU'
                                  ? "Ketik nama atau kode SPBU..."
                                  : "Ketik nama atau ID site...",
                              prefixIcon: const Icon(
                                LucideIcons.search,
                                size: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            validator: (value) => selectedSiteId == null
                                ? 'Pilih lokasi dari daftar!'
                                : null,

                            // TAMBAHAN: Biar isi textbox ke-reset tiap lu ganti unit CNOP/SPBU
                            onChanged: (val) {
                              if (selectedSiteId != null) {
                                setState(
                                  () => selectedSiteId = null,
                                ); // Reset ID kalau user ngetik ulang
                              }
                            },
                          );
                        },
                  ),
                  const SizedBox(height: 20),

                  Text(
                    "Teknisi yang Bertugas",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _showMultiSelectTechnician,
                    child: Container(
                      width: double.infinity,
                      // Fix Error 2: Ganti minHeight pakai BoxConstraints
                      constraints: const BoxConstraints(minHeight: 50),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: selectedTechnicians.isEmpty ? 14 : 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: selectedTechnicians.isEmpty
                                ? Text(
                                    "Ketik atau pilih nama teknisi...",
                                    style: TextStyle(color: Colors.grey[600]),
                                  )
                                : Wrap(
                                    spacing: 8.0,
                                    runSpacing: 4.0,
                                    children: selectedTechnicians.map((t) {
                                      return Chip(
                                        // INI YANG DIUBAH: Tambahin NIK di dalam kurung
                                        label: Text(
                                          "${t['name']} (${t['nik'] ?? '-'})",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        backgroundColor: Colors.blue[50],
                                        deleteIconColor: Colors.red[400],
                                        onDeleted: () {
                                          setState(() {
                                            selectedTechnicians.removeWhere(
                                              (item) => item['id'] == t['id'],
                                            );
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ),
                          ),
                          const Icon(
                            LucideIcons.chevronDown,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Jenis Tiket',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: ['Gangguan', 'Proaktif', 'Instalasi']
                        .map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => ticketType = val),
                    validator: (val) => val == null ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _sysNumController,
                    decoration: InputDecoration(
                      labelText: 'Nomor Sistem (IN / TKT)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _saController,
                    decoration: InputDecoration(
                      labelText: 'Service Area (SA)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Deskripsi Awal',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 30),

                  ElevatedButton(
                    onPressed: _submitTicket,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Buat Tiket",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
