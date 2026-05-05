import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:native_exif/native_exif.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gal/gal.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ExifEditorScreen extends StatefulWidget {
  const ExifEditorScreen({super.key});

  @override
  State<ExifEditorScreen> createState() => _ExifEditorScreenState();
}

class _ExifEditorScreenState extends State<ExifEditorScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  Exif? _exif;
  
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lonController = TextEditingController();

  bool _isLoading = false;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _isLoading = true;
      });

      _selectedImage = File(image.path);
      _exif = await Exif.fromPath(image.path);
      
      try {
        final dateOriginal = await _exif!.getAttribute('DateTimeOriginal');
        final latLong = await _exif!.getLatLong();

        setState(() {
          _dateController.text = dateOriginal ?? DateFormat('yyyy:MM:dd HH:mm:ss').format(DateTime.now());
          if (latLong != null) {
            _latController.text = latLong.latitude.toString();
            _lonController.text = latLong.longitude.toString();
          } else {
            _latController.text = '';
            _lonController.text = '';
          }
        });
      } catch (e) {
        print("Error reading exif: $e");
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied, we cannot request permissions.');
      } 

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _latController.text = position.latitude.toString();
        _lonController.text = position.longitude.toString();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil lokasi: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.now();
    try {
      if (_dateController.text.isNotEmpty) {
        final parts = _dateController.text.split(' ');
        if (parts.length == 2) {
          final dateParts = parts[0].split(':');
          if (dateParts.length == 3) {
            initialDate = DateTime(
              int.parse(dateParts[0]), 
              int.parse(dateParts[1]), 
              int.parse(dateParts[2])
            );
          }
        }
      }
    } catch (e) {
      print("Parse date error: $e");
    }

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );
      if (pickedTime != null) {
        final finalDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        setState(() {
          _dateController.text = DateFormat('yyyy:MM:dd HH:mm:ss').format(finalDateTime);
        });
      }
    }
  }

  Future<void> _saveExifAndExport() async {
    if (_selectedImage == null || _exif == null) return;
    setState(() => _isLoading = true);

    try {
      // 1. Write DateTimeOriginal
      if (_dateController.text.isNotEmpty) {
        await _exif!.writeAttribute('DateTimeOriginal', _dateController.text);
      }

      // 2. Write GPS Location
      if (_latController.text.isNotEmpty && _lonController.text.isNotEmpty) {
        double lat = double.parse(_latController.text);
        double lon = double.parse(_lonController.text);
        
        await _exif!.writeAttributes({
          'GPSLatitude': lat.abs().toString(),
          'GPSLatitudeRef': lat >= 0 ? 'N' : 'S',
          'GPSLongitude': lon.abs().toString(),
          'GPSLongitudeRef': lon >= 0 ? 'E' : 'W',
        });
      }

      // 3. Save to Gallery using GAL
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }
      await Gal.putImage(_selectedImage!.path);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto dengan EXIF baru berhasil disimpan ke Galeri!'), 
          backgroundColor: Colors.green
        ),
      );
      
      // Close exif
      await _exif!.close();
      
      setState(() {
        _selectedImage = null;
        _exif = null;
        _dateController.text = '';
        _latController.text = '';
        _lonController.text = '';
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan foto: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _latController.dispose();
    _lonController.dispose();
    _exif?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Edit EXIF Foto', style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black87),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.monitorOff, size: 80, color: Colors.red),
                SizedBox(height: 20),
                Text(
                  'Tidak Didukung di Web',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  'Fitur edit metadata EXIF dan menyimpan foto ke galeri (GAL) hanya didukung di aplikasi Mobile (Android & iOS). Silakan jalankan aplikasi ini di emulator atau HP asli Anda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit EXIF Foto', style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_selectedImage == null) ...[
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[400]!, style: BorderStyle.solid),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.imagePlus, size: 48, color: Colors.grey[500]),
                          const SizedBox(height: 8),
                          Text('Pilih Foto dari Galeri', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  )
                ] else ...[
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_selectedImage!, height: 250, width: double.infinity, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedImage = null;
                              _exif?.close();
                              _exif = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(LucideIcons.x, color: Colors.white, size: 20),
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Data Waktu (DateTimeOriginal)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _dateController,
                    readOnly: true,
                    onTap: () => _selectDate(context),
                    decoration: InputDecoration(
                      hintText: 'YYYY:MM:DD HH:MM:SS',
                      suffixIcon: const Icon(LucideIcons.calendar),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Data Lokasi (GPS)', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        onPressed: _getCurrentLocation, 
                        icon: const Icon(LucideIcons.mapPin, size: 16), 
                        label: const Text('Get Lokasi Saat Ini', style: TextStyle(fontSize: 12))
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _latController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                          decoration: InputDecoration(
                            labelText: 'Latitude',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _lonController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                          decoration: InputDecoration(
                            labelText: 'Longitude',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _saveExifAndExport,
                    icon: const Icon(LucideIcons.save, color: Colors.white),
                    label: const Text('Simpan ke Galeri', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ],
            ),
          ),
    );
  }
}
