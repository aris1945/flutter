import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Sesuaikan dengan IP Laravel kamu
  static const String hostUrl =
      'http://35.209.168.114';
  static const String baseUrl = '$hostUrl/api';

  // Fungsi Helper untuk GET Request
  static Future<http.Response> get(String endpoint) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    return await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  // Fungsi Helper untuk POST Request (Login dll)
  static Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    return await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
  }

  // Fungsi khusus untuk upload form beserta file gambar
  static Future<http.StreamedResponse> postMultipart(
    String endpoint,
    Map<String, String> fields,
    File? imageFile,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint'));

    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    // Masukkan data teks (status, deskripsi, odp, dll)
    request.fields.addAll(fields);

    // Masukkan file gambar jika ada
    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );
    }

    return await request.send();
  }
}
