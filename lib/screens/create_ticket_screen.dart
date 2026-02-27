import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/api_service.dart';

class CreateTicketScreen extends StatefulWidget {
  @override
  _CreateTicketScreenState createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers untuk input teks
  final _noSistemController = TextEditingController();
  final _saController = TextEditingController();
  final _siteIdController = TextEditingController();
  final _siteNameController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _petugasController = TextEditingController();

  // Dropdown values
  String _selectedUnit = 'Retail'; // Contoh default
  String _selectedJenis = 'Gangguan'; // Contoh default
  
  bool _isLoading = false;

  final List<String> _unitOptions = ['Retail', 'Corporate', 'Backbone', 'Lainnya'];
  final List<String> _jenisOptions = ['Gangguan', 'Instalasi', 'Preventive', 'Lainnya'];

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final payload = {
        'nomor_sistem': _noSistemController.text,
        'unit': _selectedUnit,
        'jenis': _selectedJenis,
        'sa': _saController.text,
        'site_id': _siteIdController.text,
        'site_name': _siteNameController.text,
        'deskripsi': _deskripsiController.text,
        'petugas': _petugasController.text, // Format: Nama (NIK)
      };

      final response = await ApiService.post('/tickets', payload);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tiket berhasil dibuat!'), backgroundColor: Colors.green));
        Navigator.pop(context, true); // Kembali ke list dan bawa nilai true buat auto-refresh
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Gagal membuat tiket'), backgroundColor: Colors.red));
      }
    } catch (e) {
      print("Error create ticket: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Terjadi kesalahan jaringan.'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Buat Tiket Baru', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black87),
        elevation: 1,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            _buildTextField("Nomor Sistem", _noSistemController, icon: LucideIcons.hash),
            SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(child: _buildDropdown("Unit", _selectedUnit, _unitOptions, (val) => setState(() => _selectedUnit = val!))),
                SizedBox(width: 16),
                Expanded(child: _buildDropdown("Jenis", _selectedJenis, _jenisOptions, (val) => setState(() => _selectedJenis = val!))),
              ],
            ),
            SizedBox(height: 16),

            Row(
              children: [
                Expanded(child: _buildTextField("Kode SA", _saController, icon: LucideIcons.map, isRequired: true)),
                SizedBox(width: 16),
                Expanded(child: _buildTextField("Site ID", _siteIdController, icon: LucideIcons.building)),
              ],
            ),
            SizedBox(height: 16),
            
            _buildTextField("Nama Site / Lokasi", _siteNameController, icon: LucideIcons.mapPin),
            SizedBox(height: 16),

            _buildTextField("Petugas (Assign Ke)", _petugasController, icon: LucideIcons.users, hint: "Contoh: Budi (1001), Andi (1002)"),
            SizedBox(height: 16),

            Text("Deskripsi Gangguan", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700])),
            SizedBox(height: 8),
            TextFormField(
              controller: _deskripsiController,
              maxLines: 4,
              validator: (value) => value!.isEmpty ? 'Deskripsi wajib diisi' : null,
              decoration: InputDecoration(
                filled: true, fillColor: Colors.white,
                hintText: "Jelaskan detail masalahnya...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
              ),
            ),
            SizedBox(height: 32),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitTicket,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _isLoading
                    ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text("BUAT TIKET", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Helper UI untuk TextField
  Widget _buildTextField(String label, TextEditingController controller, {IconData? icon, String? hint, bool isRequired = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700])),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: isRequired ? (value) => value!.isEmpty ? 'Wajib diisi' : null : null,
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon, size: 18, color: Colors.grey[500]) : null,
            hintText: hint,
            filled: true, fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
          ),
        ),
      ],
    );
  }

  // Helper UI untuk Dropdown
  Widget _buildDropdown(String label, String value, List<String> options, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700])),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              items: options.map((String val) => DropdownMenuItem(value: val, child: Text(val, style: TextStyle(fontSize: 14)))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}