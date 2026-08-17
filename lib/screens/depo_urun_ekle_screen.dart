import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/depo.dart';

/// Bir depoda henüz "olmayan" ürünleri Ürünler kataloğundan listeleyip
/// seçilenler için miktar girilmesini sağlar; "Kaydet" ile hepsi tek
/// seferde depoya eklenir. Sayım yaparken kullanılması düşünülmüştür:
/// depoda fiilen bulunan ürünler işaretlenip miktarları girilir.
class DepoUrunEkleScreen extends StatefulWidget {
  final Depo depo;
  const DepoUrunEkleScreen({super.key, required this.depo});

  @override
  State<DepoUrunEkleScreen> createState() => _DepoUrunEkleScreenState();
}

class _DepoUrunEkleScreenState extends State<DepoUrunEkleScreen> {
  final _db = DatabaseHelper.instance;
  List<Map<String, dynamic>> _urunler = [];
  bool _yukleniyor = true;
  String _arama = '';

  // urun_id -> seçili mi
  final Map<int, bool> _secili = {};
  // urun_id -> miktar metin kutusu controller'ı
  final Map<int, TextEditingController> _miktarCtrl = {};

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    final list = await _db.depodaOlmayanUrunleriGetir(widget.depo.id!);
    for (final u in list) {
      final id = u['id'] as int;
      _secili.putIfAbsent(id, () => false);
      _miktarCtrl.putIfAbsent(id, () => TextEditingController(text: '1'));
    }
    setState(() {
      _urunler = list;
      _yukleniyor = false;
    });
  }

  @override
  void dispose() {
    for (final c in _miktarCtrl.values) {
      c.dispose();
    }
    super.dispose();
  }

  int get _seciliSayisi => _secili.values.where((v) => v).length;

  Future<void> _kaydet() async {
    final girdiler = <int, double>{};
    for (final entry in _secili.entries) {
      if (!entry.value) continue;
      final urunId = entry.key;
      final metin = _miktarCtrl[urunId]?.text.trim().replaceAll(',', '.') ?? '';
      final miktar = double.tryParse(metin) ?? 0;
      if (miktar > 0) {
        girdiler[urunId] = miktar;
      }
    }
    if (girdiler.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce en az bir ürün seçip miktar girin (0\'dan büyük).')),
      );
      return;
    }
    await _db.stoklariTopluEkle(widget.depo.id!, girdiler);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final filtreli = _urunler.where((u) {
      final ad = (u['ad'] as String).toLowerCase();
      final kod = ((u['kod'] as String?) ?? '').toLowerCase();
      final q = _arama.toLowerCase();
      return ad.contains(q) || kod.contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.depo.isim} — Ürün Ekle'),
        actions: [
          TextButton(
            onPressed: _seciliSayisi == 0 ? null : _kaydet,
            child: Text(
              _seciliSayisi == 0 ? 'Kaydet' : 'Kaydet ($_seciliSayisi)',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Ürün adı veya kodu ara...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => _arama = v),
                  ),
                ),
                Expanded(
                  child: filtreli.isEmpty
                      ? Center(
                          child: Text(
                            _urunler.isEmpty
                                ? 'Eklenecek ürün yok — tüm ürünler zaten bu depoda\nya da Ürünler sekmesinde hiç ürün tanımlı değil.'
                                : 'Aramayla eşleşen ürün yok.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          itemCount: filtreli.length,
                          itemBuilder: (context, i) {
                            final u = filtreli[i];
                            final id = u['id'] as int;
                            final secili = _secili[id] ?? false;
                            final kod = u['kod'] as String?;
                            return CheckboxListTile(
                              value: secili,
                              onChanged: (v) => setState(() => _secili[id] = v ?? false),
                              title: Text(u['ad'] as String),
                              subtitle: Text('Kod: ${(kod == null || kod.isEmpty) ? "-" : kod}'),
                              secondary: SizedBox(
                                width: 90,
                                child: TextField(
                                  controller: _miktarCtrl[id],
                                  enabled: secili,
                                  textAlign: TextAlign.center,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'Miktar',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
