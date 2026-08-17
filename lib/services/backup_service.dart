import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../db/database_helper.dart';

/// Tüm veritabanını (ürünler, depolar, stoklar, kasa kayıtları) tek bir JSON
/// dosyasına yazar / o dosyadan geri yükler. Bu, uygulamanın kendi iç yedeği
/// için kullanılır (Excel'e aktarımdan farklı olarak hiçbir veri kaybı olmadan
/// birebir geri getirir).
class BackupService {
  final _db = DatabaseHelper.instance;

  Future<String> yedekAl() async {
    final urunler = await _db.urunleriGetir();
    final depolar = await _db.depolariGetir();
    final stoklar = await _db.tumStoklariGetir();
    final kasa = await _db.kasaKayitlariGetir();

    final veri = {
      'versiyon': 1,
      'tarih': DateTime.now().toIso8601String(),
      'urunler': urunler,
      'depolar': depolar,
      'stoklar': stoklar,
      'kasa_kayitlari': kasa,
    };

    final dir = await getApplicationDocumentsDirectory();
    final zamanDamgasi = DateTime.now().millisecondsSinceEpoch;
    final dosya = File('${dir.path}/inci_gida_yedek_$zamanDamgasi.json');
    await dosya.writeAsString(jsonEncode(veri));
    return dosya.path;
  }

  Future<void> yedekGeriYukle(String jsonIcerik) async {
    final veri = jsonDecode(jsonIcerik) as Map<String, dynamic>;
    if (!veri.containsKey('urunler') || !veri.containsKey('depolar')) {
      throw const FormatException('Bu dosya geçerli bir İnci Gıda yedek dosyası değil.');
    }
    await _db.tumVeriyiDegistir(
      urunler: List<Map<String, dynamic>>.from(veri['urunler'] as List),
      depolar: List<Map<String, dynamic>>.from(veri['depolar'] as List),
      stoklar: List<Map<String, dynamic>>.from(veri['stoklar'] as List),
      kasaKayitlari: List<Map<String, dynamic>>.from(veri['kasa_kayitlari'] as List),
    );
  }
}
