import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/api_service.dart';

class SpbuListScreen extends StatefulWidget {
  @override
  _SpbuListScreenState createState() => _SpbuListScreenState();
}

class _SpbuListScreenState extends State<SpbuListScreen> {
  List<dynamic> fetchSpbu = [];
  List<dynamic> filteredfetchSpbu = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchSpbu();
  }

  // Ibarat useEffect buat manggil API pas load awal
  Future<void> _fetchSpbu() async {
    setState(() => isLoading = true);
    try {
      final response = await ApiService.get(
        '/spbu',
      ); // Sesuaikan endpoint API lu
      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);

        // INI KUNCI PERUBAHANNYA: Masuk ke ['data']['data']
        final List<dynamic> siteList = decodedResponse['data']['data'];

        if (mounted) {
          setState(() {
            fetchSpbu = siteList;
            filteredfetchSpbu = siteList;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  // Fungsi buat search bar (kayak onChange di React)
  void _handleSearch(String query) {
    setState(() {
      searchQuery = query;
      
      if (query.isEmpty) {
        // Kalau kotak pencarian kosong, balikin semua data
        filteredfetchSpbu = fetchSpbu; 
      } else {
        // Kalau ada ketikan, baru di-filter
        filteredfetchSpbu = fetchSpbu.where((site) {
          // Pake .toString() biar aman jaya kalau ada data yg bukan text
          final spbuId = (site['kode_spbu'] ?? '').toString().toLowerCase();
          final spbuName = (site['nama_spbu'] ?? '').toString().toLowerCase();
          final sto = (site['sto'] ?? '').toString().toLowerCase();
          
          final searchLower = query.toLowerCase();

          // Cek apakah ketikan user ada di ID, Nama, atau STO
          return spbuId.contains(searchLower) || 
                 spbuName.contains(searchLower) || 
                 sto.contains(searchLower);
        }).toList();
      }
    });
  }

  // Fungsi delete sementara
  Future<void> _deleteSpbu(int id) async {
    // Nanti kita isi logic nembak API delete di sini
    print("Delete site ID: $id");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Data Site',
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
      body: Column(
        children: [
          // SEARCH BAR
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              onChanged: _handleSearch,
              decoration: InputDecoration(
                hintText: "Cari nama site atau unit...",
                prefixIcon: Icon(LucideIcons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // LIST DATA
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : filteredfetchSpbu.isEmpty
                ? Center(
                    child: Text(
                      "Data spbu nggak ketemu",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchSpbu,
                    child: ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: filteredfetchSpbu.length,
                      itemBuilder: (context, index) {
                        final site = filteredfetchSpbu[index];
                        return Container(
                          margin: EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue[50],
                              child: Icon(
                                LucideIcons.mapPin,
                                color: Colors.blue[700],
                              ),
                            ),
                            title: Text(
                              "${site['kode_spbu'] ?? '-'} - ${site['nama_spbu'] ?? '-'}",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text("Unit: ${site['unit'] ?? '-'}"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    LucideIcons.edit,
                                    color: Colors.orange,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    // Nanti lempar ke form edit
                                  },
                                ),
                                IconButton(
                                  icon: Icon(
                                    LucideIcons.trash2,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  onPressed: () => _deleteSpbu(site['id']),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Nanti buka halaman add site
        },
        backgroundColor: Colors.blue[700],
        child: Icon(LucideIcons.plus, color: Colors.white),
      ),
    );
  }
}
