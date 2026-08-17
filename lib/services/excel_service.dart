import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import '../db/database_helper.dart';

/// Verileri, kullanıcının orijinal Excel dosyasına benzer bir yapıda
/// (her depo kendi sayfasında, artı "Ürünler", "Genel Toplam", "Kasa"
/// sayfaları) .xlsx olarak dışa aktarır / bu yapıdaki bir dosyadan içe aktarır.
///
/// NOT: "excel" paketinin hücre okuma/yazma API'si sürümden sürüme değişebiliyor.
/// Bu kod excel: ^4.x hedeflenerek yazıldı ve bu ortamda derlenip test
/// edilemedi (bkz. proje README.md). `flutter pub get` sonrası bir tip hatası
/// çıkarsa hatayı ilet, hemen düzeltilir.
class ExcelService {
  final _db = DatabaseHelper.instance;

  static const List<String> _rezerveSayfalar = ['Ürünler', 'Genel Toplam', 'Kasa'];

  Future<String> excelExportEt() async {
    final excel = Excel.createExcel();
    final urunler = await _db.urunleriGetir();
    final depolar = await _db.depolariGetir();

    // ---- Ürünler sayfası ----
    final urunSheet = excel['Ürünler'];
    urunSheet.appendRow([
      TextCellValue('Malzeme Kodu'),
      TextCellValue('Ürün Adı'),
      TextCellValue('Satış Fiyatı'),
      TextCellValue('Alış Fiyatı'),
      TextCellValue('Kâr (TL)'),
      TextCellValue('Kâr (%)'),
    ]);
    for (final u in urunler) {
      final satis = (u['satis_fiyati'] as num).toDouble();
      final alis = (u['alis_fiyati'] as num).toDouble();
      final karTL = satis - alis;
      final karYuzde = alis == 0 ? 0.0 : (satis / alis - 1) * 100;
      urunSheet.appendRow([
        TextCellValue((u['kod'] as String?) ?? ''),
        TextCellValue(u['ad'] as String),
        DoubleCellValue(satis),
        DoubleCellValue(alis),
        DoubleCellValue(karTL),
        DoubleCellValue(karYuzde),
      ]);
    }

    // ---- Depo sayfaları ----
    for (final d in depolar) {
      final depoId = d['id'] as int;
      final sheet = excel[d['isim'] as String];
      sheet.appendRow([
        TextCellValue('Malzeme Kodu'),
        TextCellValue('Ürün Adı'),
        TextCellValue('Depo Stoğu'),
        TextCellValue('Depo Toplam Fiyat'),
      ]);
      final stoklar = await _db.depoStoklariGetir(depoId);
      for (final s in stoklar) {
        final miktar = (s['miktar'] as num).toDouble();
        final alis = (s['alis_fiyati'] as num).toDouble();
        sheet.appendRow([
          TextCellValue((s['kod'] as String?) ?? ''),
          TextCellValue(s['ad'] as String),
          DoubleCellValue(miktar),
          DoubleCellValue(miktar * alis),
        ]);
      }
    }

    // ---- Genel Toplam sayfası ----
    final genelSheet = excel['Genel Toplam'];
    genelSheet.appendRow([
      TextCellValue('Malzeme Kodu'),
      TextCellValue('Ürün Adı'),
      TextCellValue('Genel Depo'),
      TextCellValue('Depo Toplam Fiyat'),
    ]);
    final genelToplam = await _db.genelToplamGetir();
    for (final g in genelToplam) {
      final miktar = (g['toplam_miktar'] as num).toDouble();
      final alis = (g['alis_fiyati'] as num).toDouble();
      genelSheet.appendRow([
        TextCellValue((g['kod'] as String?) ?? ''),
        TextCellValue(g['ad'] as String),
        DoubleCellValue(miktar),
        DoubleCellValue(miktar * alis),
      ]);
    }

    // ---- Kasa sayfası ----
    final kasaSheet = excel['Kasa'];
    kasaSheet.appendRow([
      TextCellValue('Tarih'),
      TextCellValue('Kalem Adı'),
      TextCellValue('Tutar'),
      TextCellValue('Açıklama'),
    ]);
    final kasaKayitlari = await _db.kasaKayitlariGetir();
    for (final k in kasaKayitlari) {
      kasaSheet.appendRow([
        TextCellValue((k['tarih'] as String).split('T').first),
        TextCellValue(k['kalem_adi'] as String),
        DoubleCellValue((k['tutar'] as num).toDouble()),
        TextCellValue((k['aciklama'] as String?) ?? ''),
      ]);
    }

    try {
      excel.delete('Sheet1');
    } catch (_) {
      // Varsayılan sayfa adı sürüme göre farklı olabilir; yoksa sorun değil.
    }

    final dir = await getApplicationDocumentsDirectory();
    final zamanDamgasi = DateTime.now().millisecondsSinceEpoch;
    final path = '${dir.path}/inci_gida_$zamanDamgasi.xlsx';
    final bytes = excel.save();
    if (bytes == null) {
      throw Exception('Excel dosyası oluşturulamadı.');
    }
    File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes);
    return path;
  }

  /// Excel dosyasından ürün / depo / stok / kasa verilerini içe aktarır.
  /// Ürünler kod (veya kod boşsa ad) ile eşleştirilip güncellenir, yoksa
  /// eklenir. Kasa kayıtları mevcutlara EK olarak eklenir (üzerine yazmaz).
  Future<String> excelIceAktar(String dosyaYolu) async {
    final bytes = File(dosyaYolu).readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);
    int urunSayisi = 0, depoSayisi = 0, stokSayisi = 0, kasaSayisi = 0;

    if (excel.tables.containsKey('Ürünler')) {
      final rows = excel.tables['Ürünler']!.rows;
      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        final ad = _metinOku(row.length > 1 ? row[1] : null);
        if (ad == null || ad.isEmpty) continue;
        final kod = _metinOku(row.isNotEmpty ? row[0] : null) ?? '';
        final satis = _sayiOku(row.length > 2 ? row[2] : null);
        final alis = _sayiOku(row.length > 3 ? row[3] : null);
        await _urunEkleGuncelle(kod, ad, satis, alis);
        urunSayisi++;
      }
    }

    for (final sayfaAdi in excel.tables.keys) {
      if (_rezerveSayfalar.contains(sayfaAdi)) continue;
      final rows = excel.tables[sayfaAdi]!.rows;
      if (rows.isEmpty) continue;
      var depoId = await _depoIdBul(sayfaAdi);
      if (depoId == null) {
        depoId = await _db.depoEkle(sayfaAdi);
        depoSayisi++;
      }
      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        final ad = _metinOku(row.length > 1 ? row[1] : null);
        if (ad == null || ad.isEmpty) continue;
        final kod = _metinOku(row.isNotEmpty ? row[0] : null) ?? '';
        final miktar = _sayiOku(row.length > 2 ? row[2] : null);
        final urunId = await _urunIdBul(kod, ad);
        if (urunId != null) {
          await _db.stokGuncelle(depoId, urunId, miktar);
          stokSayisi++;
        }
      }
    }

    if (excel.tables.containsKey('Kasa')) {
      final rows = excel.tables['Kasa']!.rows;
      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        final kalemAdi = _metinOku(row.length > 1 ? row[1] : null);
        if (kalemAdi == null || kalemAdi.isEmpty) continue;
        final tarihMetin = _metinOku(row.isNotEmpty ? row[0] : null);
        DateTime tarih;
        try {
          tarih = tarihMetin == null ? DateTime.now() : DateTime.parse(tarihMetin);
        } catch (_) {
          tarih = DateTime.now();
        }
        final tutar = _sayiOku(row.length > 2 ? row[2] : null);
        final aciklama = _metinOku(row.length > 3 ? row[3] : null);
        await _db.kasaKaydiEkle({
          'tarih': tarih.toIso8601String(),
          'kalem_adi': kalemAdi,
          'tutar': tutar,
          'aciklama': (aciklama == null || aciklama.isEmpty) ? null : aciklama,
        });
        kasaSayisi++;
      }
    }

    return '$urunSayisi ürün, $depoSayisi yeni depo, $stokSayisi stok satırı, '
        '$kasaSayisi kasa kaydı içe aktarıldı.';
  }

  // ---- Hücre okuma yardımcıları ----
  // "excel" paketi sürümüne göre bir hücre değeri ham (String/num) ya da
  // sarmalanmış (CellValue -> .value) gelebilir; en fazla birkaç kat
  // sarmalamayı burada açıyoruz.
  dynamic _ham(dynamic hucre) {
    dynamic mevcut = hucre;
    for (var i = 0; i < 3; i++) {
      if (mevcut == null) return null;
      try {
        final ic = (mevcut as dynamic).value;
        if (ic == null || identical(ic, mevcut)) break;
        mevcut = ic;
      } catch (_) {
        break;
      }
    }
    return mevcut;
  }

  String? _metinOku(dynamic hucre) {
    final v = _ham(hucre);
    if (v == null) return null;
    return v.toString();
  }

  double _sayiOku(dynamic hucre) {
    final v = _ham(hucre);
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '.')) ?? 0;
  }

  Future<int?> _depoIdBul(String isim) async {
    final depolar = await _db.depolariGetir();
    for (final d in depolar) {
      if (d['isim'] == isim) return d['id'] as int;
    }
    return null;
  }

  Future<int?> _urunIdBul(String kod, String ad) async {
    final urunler = await _db.urunleriGetir();
    for (final u in urunler) {
      if (kod.isNotEmpty && u['kod'] == kod) return u['id'] as int;
    }
    for (final u in urunler) {
      if (u['ad'] == ad) return u['id'] as int;
    }
    return null;
  }

  Future<void> _urunEkleGuncelle(String kod, String ad, double satis, double alis) async {
    final mevcutId = await _urunIdBul(kod, ad);
    final map = {'kod': kod, 'ad': ad, 'satis_fiyati': satis, 'alis_fiyati': alis};
    if (mevcutId != null) {
      await _db.urunGuncelle(mevcutId, map);
    } else {
      await _db.urunEkle(map);
    }
  }
}
