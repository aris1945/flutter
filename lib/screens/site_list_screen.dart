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

  Future<void> _fetchSites() async {
    setState(() => isLoading = true);
    try {
      final response = await ApiService.get('/sites');
      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
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

  void _handleSearch(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredSites = sites;
      } else {
        filteredSites = sites.where((site) {
          final siteId = (site['site_id'] ?? '').toString().toLowerCase();
          final siteName = (site['site_name'] ?? '').toString().toLowerCase();
          final sto = (site['sto'] ?? '').toString().toLowerCase();
          final searchLower = query.toLowerCase();

          return siteId.contains(searchLower) ||
              siteName.contains(searchLower) ||
              sto.contains(searchLower);
        }).toList();
      }
    });
  }

  Future<void> _deleteSite(int id) async {
    print("Delete site ID: $id");
  }

  // ====================================================================
  // JURUS MODAL DETAIL SITE (PERSIS KAYAK SiteDetailModal.jsx LU!)
  // ====================================================================
  void _showSiteDetailModal(BuildContext context, dynamic site) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ), // Maksimal tinggi 80% layar
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- HEADER MODAL BIRU ---
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              site['site_id'] ?? '-',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              site['site_name'] ?? '-',
                              style: TextStyle(
                                color: Colors.blue[100],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(LucideIcons.x, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // --- BODY MODAL (BISA DI-SCROLL) ---
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Group 1: Informasi Dasar
                        _buildDetailGroup('Informasi Dasar', {
                          'STO': site['sto'],
                          'PIC WAN': site['pic_wan'],
                        }),

                        // Group 2: Perangkat OLT
                        _buildDetailGroup('Perangkat OLT', {
                          'Nama OLT': site['olt'],
                          'Port OLT': site['port_olt'],
                          'Metro': site['metro'],
                          'Port Metro': site['port_metro'],
                        }),

                        // Group 3: Data Teknis (ODP)
                        _buildDetailGroup('Data Teknis', {
                          'Nama ODP': site['odp'],
                          'Koordinat ODP':
                              site['latlong_odp'], // Belum dipasang url_launcher, jadi teks biasa dlu
                        }),

                        // Group 4: Konfigurasi VLAN
                        Text(
                          'KONFIGURASI VLAN',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.grey[500],
                            letterSpacing: 1,
                          ),
                        ),
                        Divider(color: Colors.grey[300]),
                        SizedBox(height: 8),
                        GridView.count(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 3,
                          children: [
                            _buildVlanBox(
                              'VLAN 2G',
                              site['vlan_2g'],
                              Colors.blue,
                            ),
                            _buildVlanBox(
                              'VLAN 3G',
                              site['vlan_3g'],
                              Colors.blue,
                            ),
                            _buildVlanBox(
                              'VLAN 4G',
                              site['vlan_4g'],
                              Colors.blue,
                            ),
                            _buildVlanBox(
                              'VLAN OAM',
                              site['vlan_oam'],
                              Colors.grey,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // --- FOOTER MODAL ---
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                    border: Border(top: BorderSide(color: Colors.grey[200]!)),
                  ),
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.black87,
                      elevation: 0,
                    ),
                    child: Text(
                      'Tutup',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget Helper Buat Nampilin Data Berderet
  Widget _buildDetailGroup(String title, Map<String, dynamic> data) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.grey[500],
              letterSpacing: 1,
            ),
          ),
          Divider(color: Colors.grey[300]),
          SizedBox(height: 8),
          ...data.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      entry.key,
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                  ),
                  Expanded(
                    child: SelectableText(
                      // Pake SelectableText biar teknisi gampang copas
                      (entry.value == null || entry.value == '')
                          ? '-'
                          : entry.value.toString(),
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // Widget Helper Buat Kotak-Kotak VLAN
  Widget _buildVlanBox(String title, dynamic value, MaterialColor color) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color.shade700,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2),
          Text(
            (value == null || value == '') ? '-' : value.toString(),
            style: TextStyle(
              color: Colors.black87,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  // ====================================================================

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
                            // NAH INI PELATUK ONTAP-NYA DIPASANG DI SINI!
                            titleAlignment: ListTileTitleAlignment.center,
                            onTap: () => _showSiteDetailModal(context, site),

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

                            //subtitle: Text(""),
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
