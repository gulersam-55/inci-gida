class Depo {
  final int? id;
  final String isim;

  Depo({this.id, required this.isim});

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'isim': isim,
      };

  factory Depo.fromMap(Map<String, dynamic> map) => Depo(
        id: map['id'] as int?,
        isim: map['isim'] as String,
      );
}
