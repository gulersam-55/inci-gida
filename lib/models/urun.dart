class Urun {
  final int? id;
  final String kod;
  final String ad;
  final double satisFiyati;
  final double alisFiyati;

  Urun({
    this.id,
    required this.kod,
    required this.ad,
    required this.satisFiyati,
    required this.alisFiyati,
  });

  // Kâr hesaplamaları veritabanında saklanmaz, her zaman canlı hesaplanır
  double get karTL => satisFiyati - alisFiyati;
  double get karYuzde => alisFiyati == 0 ? 0 : (satisFiyati / alisFiyati - 1) * 100;

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'kod': kod,
        'ad': ad,
        'satis_fiyati': satisFiyati,
        'alis_fiyati': alisFiyati,
      };

  factory Urun.fromMap(Map<String, dynamic> map) => Urun(
        id: map['id'] as int?,
        kod: (map['kod'] as String?) ?? '',
        ad: map['ad'] as String,
        satisFiyati: (map['satis_fiyati'] as num).toDouble(),
        alisFiyati: (map['alis_fiyati'] as num).toDouble(),
      );
}
