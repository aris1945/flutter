import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/api_service.dart';

class UpdateWorklogScreen extends StatefulWidget {
  final Map<String, dynamic> ticket;

  UpdateWorklogScreen({required this.ticket});

  @override
  _UpdateWorklogScreenState createState() => _UpdateWorklogScreenState();
}

class _UpdateWorklogScreenState extends State<UpdateWorklogScreen> {
  final _deskripsiController = TextEditingController();
  final _odpController = TextEditingController();
  final _odcController = TextEditingController();
  final _ftmController = TextEditingController();

  String _selectedStatus = 'In Progress';
  File? _imageFile;
  bool _isLoading = false;

  final List<String> _statusOptions = [
    'Open',
    'On The Way',
    'On Site',
    'In Progress',
    'Pending',
    'Closed',
  ];

  @override
  void initState() {
    super.initState();
    // Set default status sesuai status tiket saat ini
    if (_statusOptions.contains(widget.ticket['status'])) {
      _selectedStatus = widget.ticket['status'];
    }
    // Isi data segmentasi jika sebelumnya sudah ada
    _odpController.text = widget.ticket['odp'] ?? '';
    _odcController.text = widget.ticket['odc'] ?? '';
    _ftmController.text = widget.ticket['ftm'] ?? '';
  }

  // Fungsi buka kamera
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    ); // Quality 70 biar gak berat uploadnya

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // Fungsi submit data ke Laravel
  Future<void> _submitWorklog() async {
    if (_deskripsiController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deskripsi pekerjaan wajib diisi!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Siapkan data teks
      Map<String, String> fields = {
        'status': _selectedStatus,
        'deskripsi': _deskripsiController.text,
        'odp': _odpController.text,
        'odc': _odcController.text,
        'ftm': _ftmController.text,
      };

      // Tembak ke API addLog Laravel kamu
      final response = await ApiService.postMultipart(
        '/tickets/${widget.ticket['id']}/log',
        fields,
        _imageFile,
      );

      final responseData = await response.stream.bytesToString();
      final data = jsonDecode(responseData);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Worklog berhasil diupdate!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(
          context,
          true,
        ); // Kembali ke halaman sebelumnya dan bawa nilai 'true' (tanda sukses)
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Gagal update worklog'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Error upload worklog: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan jaringan.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Update ${widget.ticket['nomor_internal']}',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black87),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dropdown Status
            Text(
              "Update Status",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedStatus,
                  isExpanded: true,
                  items: _statusOptions.map((String val) {
                    return DropdownMenuItem<String>(
                      value: val,
                      child: Text(val),
                    );
                  }).toList(),
                  onChanged: (newVal) =>
                      setState(() => _selectedStatus = newVal!),
                ),
              ),
            ),
            SizedBox(height: 16),

            // Deskripsi Pekerjaan
            Text(
              "Deskripsi Pekerjaan / Keterangan",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _deskripsiController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Contoh: Kabel putus sudah disambung...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),
            SizedBox(height: 16),

            // Segmentasi (ODP, ODC, FTM)
            // Row(
            //   children: [
            //     Expanded(child: _buildTextField("ODP", _odpController)),
            //     SizedBox(width: 12),
            //     Expanded(child: _buildTextField("ODC", _odcController)),
            //     SizedBox(width: 12),
            //     Expanded(child: _buildTextField("FTM", _ftmController)),
            //   ],
            // ),
            SizedBox(height: 24),

            // Area Foto Evident
            Text(
              "Foto Evident",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            InkWell(
              onTap: _pickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue[200]!,
                    style: BorderStyle.solid,
                  ),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_imageFile!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.camera,
                            size: 40,
                            color: Colors.blue[400],
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Tap untuk ambil foto",
                            style: TextStyle(
                              color: Colors.blue[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            SizedBox(height: 32),

            // Tombol Submit
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitWorklog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        "SIMPAN WORKLOG",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 4),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
          ),
        ),
      ],
    );
  }
}
