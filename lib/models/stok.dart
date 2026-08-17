class Stok {
  final int? id;
  final int depoId;
  final int urunId;
  final double miktar;

  Stok({
    this.id,
    required this.depoId,
    required this.urunId,
    required this.miktar,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'depo_id': depoId,
        'urun_id': urunId,
        'miktar': miktar,
      };

  factory Stok.fromMap(Map<String, dynamic> map) => Stok(
        id: map['id'] as int?,
        depoId: map['depo_id'] as int,
        urunId: map['urun_id'] as int,
        miktar: (map['miktar'] as num).toDouble(),
      );
}
