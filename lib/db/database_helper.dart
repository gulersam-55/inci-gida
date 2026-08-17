import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Tüm veriler telefonun kendi dosya sisteminde tek bir SQLite dosyasında
/// (inci_gida.db) tutulur. İnternet bağlantısı, sunucu ya da başka bir
/// kullanıcı YOKTUR. Uygulama kaldırılırsa veya "uygulama verilerini temizle"
/// yapılırsa bu dosya da silinir.
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'inci_gida.db');

    // İlk açılışta (bu dosya telefonda henüz yoksa) uygulamayla birlikte
    // gelen, ürün listenizin ve depo isimlerinizin önceden yüklü olduğu
    // veritabanı kopyalanır. Böylece kurulumdan hemen sonra Ürünler ve
    // Depolar sekmeleri boş gelmez. Bu sadece İLK kurulumda çalışır — daha
    // sonra Ayarlar'dan yaptığınız değişiklikler/içe aktarımlar bu dosyanın
    // üzerine yazılmaz, hep aynı `inci_gida.db` kullanılır.
    if (!await File(path).exists()) {
      try {
        await Directory(dirname(path)).create(recursive: true);
        final veri = await rootBundle.load('assets/db/inci_gida_seed.db');
        final bytes = veri.buffer.asUint8List(veri.offsetInBytes, veri.lengthInBytes);
        await File(path).writeAsBytes(bytes, flush: true);
      } catch (_) {
        // Varlık dosyası bulunamazsa/okunamazsa sorun değil — openDatabase
        // aşağıda onCreate ile boş ama doğru şemalı bir veritabanı oluşturur.
      }
    }

    return openDatabase(
      path,
      version: 1,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE urunler (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            kod TEXT,
            ad TEXT NOT NULL,
            satis_fiyati REAL NOT NULL DEFAULT 0,
            alis_fiyati REAL NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE depolar (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            isim TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE stoklar (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            depo_id INTEGER NOT NULL,
            urun_id INTEGER NOT NULL,
            miktar REAL NOT NULL DEFAULT 0,
            UNIQUE(depo_id, urun_id),
            FOREIGN KEY (depo_id) REFERENCES depolar(id) ON DELETE CASCADE,
            FOREIGN KEY (urun_id) REFERENCES urunler(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE kasa_kayitlari (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tarih TEXT NOT NULL,
            kalem_adi TEXT NOT NULL,
            tutar REAL NOT NULL,
            aciklama TEXT
          )
        ''');
      },
    );
  }

  // ---------------- ÜRÜNLER ----------------

  Future<int> urunEkle(Map<String, dynamic> urunMap) async {
    final db = await database;
    // Not: Yeni ürün eklenince artık hiçbir depoya otomatik stok satırı
    // açılmıyor. Bir ürün, ancak bir depoda "Stok Ekle" ile eklenip miktar
    // girildiğinde o deponun listesinde görünür (bkz. depoStoklariGetir).
    return db.insert('urunler', urunMap);
  }

  Future<int> urunGuncelle(int id, Map<String, dynamic> urunMap) async {
    final db = await database;
    return db.update('urunler', urunMap, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> urunSil(int id) async {
    final db = await database;
    return db.delete('urunler', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> urunleriGetir() async {
    final db = await database;
    return db.query('urunler', orderBy: 'ad ASC');
  }

  // ---------------- DEPOLAR ----------------

  Future<int> depoEkle(String isim) async {
    final db = await database;
    // Not: Yeni depo boş açılır; ürünler bu depoya "Stok Ekle" ile tek tek
    // (veya Excel içe aktarımla) eklenir.
    return db.insert('depolar', {'isim': isim});
  }

  Future<int> depoSil(int id) async {
    final db = await database;
    return db.delete('depolar', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> depolariGetir() async {
    final db = await database;
    return db.query('depolar', orderBy: 'isim ASC');
  }

  // ---------------- STOKLAR ----------------

  Future<void> stokGuncelle(int depoId, int urunId, double miktar) async {
    final db = await database;
    final mevcut = await db.query('stoklar',
        where: 'depo_id = ? AND urun_id = ?', whereArgs: [depoId, urunId]);
    if (mevcut.isEmpty) {
      await db.insert('stoklar', {'depo_id': depoId, 'urun_id': urunId, 'miktar': miktar});
    } else {
      await db.update('stoklar', {'miktar': miktar},
          where: 'depo_id = ? AND urun_id = ?', whereArgs: [depoId, urunId]);
    }
  }

  /// Bir deponun İÇİNDEKİ ürünleri döner — yalnızca bu depoda stok miktarı
  /// 0'dan büyük olan (yani fiilen "depoda olan") ürünler listelenir.
  /// Bir ürünü depoya dahil etmek için depodaOlmayanUrunleriGetir() ile
  /// listeleyip stokEkle() ile miktar girilmesi gerekir. Miktarı 0'a
  /// düşürülen bir ürün otomatik olarak bu listeden kalkar.
  Future<List<Map<String, dynamic>>> depoStoklariGetir(int depoId) async {
    final db = await database;
    return db.rawQuery('''
      SELECT u.id as urun_id, u.kod, u.ad, u.satis_fiyati, u.alis_fiyati,
             s.miktar as miktar
      FROM stoklar s
      JOIN urunler u ON u.id = s.urun_id
      WHERE s.depo_id = ? AND s.miktar > 0
      ORDER BY u.ad ASC
    ''', [depoId]);
  }

  /// Bu depoda henüz "olmayan" (stok miktarı 0 veya hiç satırı olmayan)
  /// ürünleri döner — "Stok Ekle" ekranında seçilecek listedir.
  Future<List<Map<String, dynamic>>> depodaOlmayanUrunleriGetir(int depoId) async {
    final db = await database;
    return db.rawQuery('''
      SELECT u.id, u.kod, u.ad, u.satis_fiyati, u.alis_fiyati
      FROM urunler u
      WHERE u.id NOT IN (
        SELECT urun_id FROM stoklar WHERE depo_id = ? AND miktar > 0
      )
      ORDER BY u.ad ASC
    ''', [depoId]);
  }

  /// Seçilen birden çok ürünü, girilen miktarlarla birlikte tek seferde
  /// bu depoya ekler (Depo Detay > Stok Ekle ekranında kullanılır).
  Future<void> stoklariTopluEkle(int depoId, Map<int, double> urunMiktarlari) async {
    final db = await database;
    final batch = db.batch();
    for (final girdi in urunMiktarlari.entries) {
      batch.insert(
        'stoklar',
        {'depo_id': depoId, 'urun_id': girdi.key, 'miktar': girdi.value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Tüm depolardaki stokların ürün bazında toplamı (Excel'deki "Genel Toplam" sayfası).
  Future<List<Map<String, dynamic>>> genelToplamGetir() async {
    final db = await database;
    return db.rawQuery('''
      SELECT u.id as urun_id, u.kod, u.ad, u.alis_fiyati,
             COALESCE(SUM(s.miktar), 0) as toplam_miktar
      FROM urunler u
      LEFT JOIN stoklar s ON s.urun_id = u.id
      GROUP BY u.id
      ORDER BY u.ad ASC
    ''');
  }

  // ---------------- KASA ----------------

  Future<int> kasaKaydiEkle(Map<String, dynamic> kayitMap) async {
    final db = await database;
    return db.insert('kasa_kayitlari', kayitMap);
  }

  Future<int> kasaKaydiSil(int id) async {
    final db = await database;
    return db.delete('kasa_kayitlari', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> kasaKayitlariGetir() async {
    final db = await database;
    return db.query('kasa_kayitlari', orderBy: 'tarih DESC, id DESC');
  }

  Future<List<String>> kasaKalemAdlariGetir() async {
    final db = await database;
    final rows = await db.rawQuery(
        'SELECT DISTINCT kalem_adi FROM kasa_kayitlari ORDER BY kalem_adi ASC');
    return rows.map((r) => r['kalem_adi'] as String).toList();
  }

  // ---------------- YEDEKLEME ----------------

  /// Ham stok tablosunun tamamı (depo_id / urun_id ilişkileriyle birlikte) —
  /// tam yedek dosyasında kullanılır.
  Future<List<Map<String, dynamic>>> tumStoklariGetir() async {
    final db = await database;
    return db.query('stoklar');
  }

  /// Mevcut tüm veriyi siler ve verilen yedek veriyle değiştirir.
  /// Tek bir transaction içinde çalışır: bir hata olursa hiçbir değişiklik
  /// kalıcı olmaz (ya hep ya hiç).
  Future<void> tumVeriyiDegistir({
    required List<Map<String, dynamic>> urunler,
    required List<Map<String, dynamic>> depolar,
    required List<Map<String, dynamic>> stoklar,
    required List<Map<String, dynamic>> kasaKayitlari,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('stoklar');
      await txn.delete('kasa_kayitlari');
      await txn.delete('urunler');
      await txn.delete('depolar');
      for (final u in urunler) {
        await txn.insert('urunler', Map<String, dynamic>.from(u));
      }
      for (final d in depolar) {
        await txn.insert('depolar', Map<String, dynamic>.from(d));
      }
      for (final s in stoklar) {
        await txn.insert('stoklar', Map<String, dynamic>.from(s));
      }
      for (final k in kasaKayitlari) {
        await txn.insert('kasa_kayitlari', Map<String, dynamic>.from(k));
      }
    });
  }
}
