class KasaKaydi {
  final int? id;
  final DateTime tarih;
  final String kalemAdi;
  final double tutar; // gider: negatif, gelir: pozitif
  final String? aciklama;

  KasaKaydi({
    this.id,
    required this.tarih,
    required this.kalemAdi,
    required this.tutar,
    this.aciklama,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'tarih': tarih.toIso8601String(),
        'kalem_adi': kalemAdi,
        'tutar': tutar,
        'aciklama': aciklama,
      };

  factory KasaKaydi.fromMap(Map<String, dynamic> map) => KasaKaydi(
        id: map['id'] as int?,
        tarih: DateTime.parse(map['tarih'] as String),
        kalemAdi: map['kalem_adi'] as String,
        tutar: (map['tutar'] as num).toDouble(),
        aciklama: map['aciklama'] as String?,
      );
}
