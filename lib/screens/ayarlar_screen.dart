import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../services/backup_service.dart';
import '../services/excel_service.dart';

class AyarlarScreen extends StatefulWidget {
  const AyarlarScreen({super.key});

  @override
  State<AyarlarScreen> createState() => _AyarlarScreenState();
}

class _AyarlarScreenState extends State<AyarlarScreen> {
  bool _yukleniyor = false;
  final _excelServisi = ExcelService();
  final _yedekServisi = BackupService();

  Future<void> _isleBasla(Future<void> Function() islem) async {
    setState(() => _yukleniyor = true);
    try {
      await islem();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  Future<void> _excelAktar() async {
    await _isleBasla(() async {
      final yol = await _excelServisi.excelExportEt();
      await Share.shareXFiles([XFile(yol)], text: 'İnci Gıda - Excel Verisi');
    });
  }

  Future<void> _excelIceAktar() async {
    final sonuc = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    if (sonuc == null || sonuc.files.single.path == null) return;
    await _isleBasla(() async {
      final mesaj = await _excelServisi.excelIceAktar(sonuc.files.single.path!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mesaj)));
      }
    });
  }

  Future<void> _yedekAl() async {
    await _isleBasla(() async {
      final yol = await _yedekServisi.yedekAl();
      await Share.shareXFiles([XFile(yol)], text: 'İnci Gıda - Tam Yedek');
    });
  }

  Future<void> _yedektenGeriYukle() async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Yedekten Geri Yükle'),
        content: const Text(
            'Bu işlem şu anki tüm verileri (ürünler, depolar, stoklar, kasa) silip '
            'seçeceğiniz yedek dosyasındaki verilerle değiştirir. Emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Devam Et')),
        ],
      ),
    );
    if (onay != true) return;

    final sonuc = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (sonuc == null || sonuc.files.single.path == null) return;

    await _isleBasla(() async {
      final dosya = File(sonuc.files.single.path!);
      final icerik = await dosya.readAsString();
      await _yedekServisi.yedekGeriYukle(icerik);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Yedek başarıyla geri yüklendi.')));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Excel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.upload_file, color: Colors.green),
                    title: const Text('Excel\'e Aktar'),
                    subtitle: const Text(
                        'Ürün, depo ve kasa verilerini .xlsx olarak dışa aktar ve paylaş (Drive, WhatsApp, e-posta vb.)'),
                    onTap: _excelAktar,
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.download, color: Colors.blue),
                    title: const Text('Excel\'den İçe Aktar'),
                    subtitle: const Text(
                        'Bu uygulamanın ürettiği (veya aynı sayfa yapısındaki) bir .xlsx dosyasından veri yükle'),
                    onTap: _excelIceAktar,
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Yedekleme', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.backup, color: Colors.green),
                    title: const Text('Yedek Al'),
                    subtitle: const Text('Tüm veriyi tek bir dosyaya kaydet ve paylaş — birebir geri yüklenebilir'),
                    onTap: _yedekAl,
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.restore, color: Colors.orange),
                    title: const Text('Yedekten Geri Yükle'),
                    subtitle: const Text('Mevcut verinin üzerine bir yedek dosyasını yükle'),
                    onTap: _yedektenGeriYukle,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Not: Yedek dosyası (.json) uygulamanın kendi verisini birebir korur. '
                  'Excel dosyası (.xlsx) ise Excel\'de açılabilir, düzenlenebilir ve tekrar '
                  'içe aktarılabilir ama biçimlendirme içermez, sadece veridir.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
    );
  }
}
