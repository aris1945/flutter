import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/api_service.dart';

class SiteListScreen extends StatefulWidget {
  @override
  _SiteListScreenState createState() => _SiteListScreenState();
}

class _SiteListScreenState extends State<SiteListScreen> {
  List<dynamic> sites = [];
  List<dynamic> filteredSites = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchSites();
  }

  // Ibarat useEffect buat manggil API pas load awal
  Future<void> _fetchSites() async {
    setState(() => isLoading = true);
    try {
      final response = await ApiService.get(
        '/sites',
      ); // Sesuaikan endpoint API lu
      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);

        // INI KUNCI PERUBAHANNYA: Masuk ke ['data']['data']
        final List<dynamic> siteList = decodedResponse['data']['data'];

        if (mounted) {
          setState(() {
            sites = siteList;
            filteredSites = siteList;
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
        filteredSites = sites; 
      } else {
        // Kalau ada ketikan, baru di-filter
        filteredSites = sites.where((site) {
          // Pake .toString() biar aman jaya kalau ada data yg bukan text
          final siteId = (site['site_id'] ?? '').toString().toLowerCase();
          final siteName = (site['site_name'] ?? '').toString().toLowerCase();
          final sto = (site['sto'] ?? '').toString().toLowerCase();
          
          final searchLower = query.toLowerCase();

          // Cek apakah ketikan user ada di ID, Nama, atau STO
          return siteId.contains(searchLower) || 
                 siteName.contains(searchLower) || 
                 sto.contains(searchLower);
        }).toList();
      }
    });
  }

  // Fungsi delete sementara
  Future<void> _deleteSite(int id) async {
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
                : filteredSites.isEmpty
                ? Center(
                    child: Text(
                      "Data site nggak ketemu",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchSites,
                    child: ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: filteredSites.length,
                      itemBuilder: (context, index) {
                        final site = filteredSites[index];
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
                              "${site['site_id'] ?? '-'} - ${site['site_name'] ?? '-'}",
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
                                  onPressed: () => _deleteSite(site['id']),
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
