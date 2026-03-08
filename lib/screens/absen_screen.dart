import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';

class AbsenScreen extends StatefulWidget {
  const AbsenScreen({super.key});

  @override
  State<AbsenScreen> createState() => _AbsenScreenState();
}

class _AbsenScreenState extends State<AbsenScreen> {
  bool isLoading = false;
  bool isGettingLocation = true;
  Position? currentPosition;
  String locationError = '';
  
  // Variabel nampung status tombol
  String statusAbsen = 'loading'; 

  @override
  void initState() {
    super.initState();
    _initHalaman();
  }

  Future<void> _initHalaman() async {
    await _cekStatusAbsen();
    await _getCurrentLocation();
  }

  // JURUS CEK STATUS KE SERVER
  Future<void> _cekStatusAbsen() async {
    try {
      final response = await ApiService.get('/absen-status'); 
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            statusAbsen = data['status'];
          });
        }
      }
    } catch (e) {
      print("Gagal cek status: $e");
      if (mounted) setState(() => statusAbsen = 'error');
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      isGettingLocation = true;
      locationError = '';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('GPS HP lu mati Bos! Nyalain dulu.');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw Exception('Izin lokasi ditolak!');
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi diblokir permanen dari HP lu.');
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      if (mounted) {
        setState(() {
          currentPosition = position;
          isGettingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          locationError = e.toString();
          isGettingLocation = false;
        });
      }
    }
  }

  // JURUS BARU: POPUP KONFIRMASI BIAR GAK MABOK
  void _showConfirmationDialog() {
    if (currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tunggu dapet lokasi dulu Bos!'), backgroundColor: Colors.red));
      return;
    }

    // Teks popupnya beda tergantung dia mau masuk apa pulang
    String title = statusAbsen == 'belum_absen' ? 'Konfirmasi Absen Masuk' : 'Konfirmasi Absen Pulang';
    String content = statusAbsen == 'belum_absen' 
        ? 'Yakin mau absen masuk sekarang? Pastiin lu udah di lokasi kerjaan ya jing, jangan absen dari kasur!' 
        : 'Yakin mau absen pulang? Kerjaan narik kabel lu udah beres semua kan?';

    showDialog(
      context: context,
      barrierDismissible: false, // Biar gak bisa ditutup sembarangan klik luar kotak
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              Icon(
                statusAbsen == 'belum_absen' ? LucideIcons.logIn : LucideIcons.logOut, 
                color: statusAbsen == 'belum_absen' ? Colors.blue : Colors.red
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
            ],
          ),
          content: Text(content, style: const TextStyle(fontSize: 15)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Tutup dialog doang
              child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialognya dulu
                _submitAbsen(); // BARU HAJAR TEMBAK API-NYA!
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: statusAbsen == 'belum_absen' ? Colors.blue.shade700 : Colors.red.shade600,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Lanjutkan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // FUNGSI SAKTI GABUNGAN TEMBAK API
  Future<void> _submitAbsen() async {
    setState(() => isLoading = true);

    try {
      final payload = {
        'latitude': currentPosition!.latitude,
        'longitude': currentPosition!.longitude,
      };

      String url = statusAbsen == 'belum_absen' ? '/absen-masuk' : '/absen-pulang';
      final response = await ApiService.post(url, payload);
      
      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final resData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resData['message'] ?? 'Sukses!'), backgroundColor: Colors.green),
        );
        await _cekStatusAbsen(); 
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorData['message'] ?? 'Gagal absen nih!'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error jaringan: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Absensi Kehadiran', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, color: Colors.blue),
            onPressed: _initHalaman,
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            height: screenHeight * 0.4, 
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFEEEEEE),
              border: Border(bottom: BorderSide(color: Colors.black12, width: 1)),
            ),
            child: isGettingLocation
                ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(), SizedBox(height: 10), Text("Nyari satelit bentar...", style: TextStyle(color: Colors.grey))]))
                : locationError.isNotEmpty
                    ? Center(child: Padding(padding: const EdgeInsets.all(20.0), child: Text(locationError, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))))
                    : FlutterMap(
                        options: MapOptions(initialCenter: LatLng(currentPosition!.latitude, currentPosition!.longitude), initialZoom: 16.0),
                        children: [
                          TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.aris.wanmonitor'),
                          MarkerLayer(markers: [Marker(point: LatLng(currentPosition!.latitude, currentPosition!.longitude), width: 50, height: 50, child: const Icon(Icons.location_on, color: Colors.red, size: 40))]),
                        ],
                      ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Lokasi Ditemukan!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(
                    currentPosition != null ? "Lat: ${currentPosition!.latitude}\nLng: ${currentPosition!.longitude}" : "Lokasi belum dapet jing",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 30),

                  if (statusAbsen == 'loading')
                    const CircularProgressIndicator()
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        // NAH DISINI GUE GANTI PANGGIL FUNGSI POPUPNYA DULU!
                        onPressed: (isLoading || currentPosition == null || statusAbsen == 'sudah_pulang') ? null : _showConfirmationDialog,
                        icon: isLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                          : Icon(
                              statusAbsen == 'belum_absen' ? LucideIcons.logIn : 
                              statusAbsen == 'sudah_masuk' ? LucideIcons.logOut : LucideIcons.checkCircle
                            ),
                        label: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Text(
                            isLoading ? 'Memproses...' : 
                            statusAbsen == 'belum_absen' ? 'ABSEN MASUK SEKARANG' :
                            statusAbsen == 'sudah_masuk' ? 'ABSEN PULANG SEKARANG' :
                            'SUDAH SELESAI SHIFT HARI INI', 
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: statusAbsen == 'belum_absen' ? Colors.blue.shade700 : 
                                           statusAbsen == 'sudah_masuk' ? Colors.red.shade600 : Colors.grey.shade400,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          disabledBackgroundColor: Colors.grey[300],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}