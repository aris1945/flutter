class Site {
  final int id;
  final String nama;
  final String alamat;

  Site({required this.id, required this.nama, required this.alamat});

  factory Site.fromJson(Map<String, dynamic> json) {
    return Site(
      id: json['id'],
      nama: json['site_name'] ?? '-',
      alamat: json['address'] ?? '-',
    );
  }
}