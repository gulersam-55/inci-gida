import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/depo.dart';
import 'depo_urun_ekle_screen.dart';

class DepoDetayScreen extends StatefulWidget {
  final Depo depo;
  const DepoDetayScreen({super.key, required this.depo});

  @override
  State<DepoDetayScreen> createState() => _DepoDetayScreenState();
}

class _DepoDetayScreenState extends State<DepoDetayScreen> {
  final _db = DatabaseHelper.instance;
  List<Map<String, dynamic>> _stoklar = [];
  final _fmt = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    final list = await _db.depoStoklariGetir(widget.depo.id!);
    setState(() => _stoklar = list);
  }

  double get _toplamDeger =>
      _stoklar.fold(0.0, (t, s) => t + (s['miktar'] as num) * (s['alis_fiyati'] as num));

  Future<void> _miktarDuzenle(Map<String, dynamic> satir) async {
    final ctrl = TextEditingController(text: (satir['miktar'] as num).toString());
    final yeni = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(satir['ad'] as String),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Stok Miktarı'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, '0'),
            child: const Text('Depodan Çıkar'),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: const Text('Kaydet')),
        ],
      ),
    );
    final miktar = double.tryParse((yeni ?? '').replaceAll(',', '.'));
    if (miktar != null) {
      await _db.stokGuncelle(widget.depo.id!, satir['urun_id'] as int, miktar);
      _yukle();
    }
  }

  Future<void> _stokEkle() async {
    final eklendiMi = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => DepoUrunEkleScreen(depo: widget.depo)),
    );
    if (eklendiMi == true) {
      _yukle();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.depo.isim)),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.primaryContainer,
            padding: const EdgeInsets.all(16),
            child: Text('Depo Toplam Değeri: ${_fmt.format(_toplamDeger)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Expanded(
            child: _stoklar.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Bu depoda henüz ürün yok.\nSağ alttaki "+" ile ürün ekleyin.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _stoklar.length,
                    itemBuilder: (context, i) {
                      final s = _stoklar[i];
                      final miktar = s['miktar'] as num;
                      final toplam = miktar * (s['alis_fiyati'] as num);
                      final kod = s['kod'] as String?;
                      return ListTile(
                        title: Text(s['ad'] as String),
                        subtitle: Text('Kod: ${(kod == null || kod.isEmpty) ? "-" : kod}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('$miktar adet', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(_fmt.format(toplam), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        onTap: () => _miktarDuzenle(s),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _stokEkle,
        tooltip: 'Depoya Ürün Ekle',
        child: const Icon(Icons.add),
      ),
    );
  }
}
