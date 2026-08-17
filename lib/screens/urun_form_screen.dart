import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/urun.dart';

class UrunFormScreen extends StatefulWidget {
  final Urun? urun;
  const UrunFormScreen({super.key, this.urun});

  @override
  State<UrunFormScreen> createState() => _UrunFormScreenState();
}

class _UrunFormScreenState extends State<UrunFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _kodCtrl;
  late TextEditingController _adCtrl;
  late TextEditingController _satisCtrl;
  late TextEditingController _alisCtrl;
  final _db = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _kodCtrl = TextEditingController(text: widget.urun?.kod ?? '');
    _adCtrl = TextEditingController(text: widget.urun?.ad ?? '');
    _satisCtrl = TextEditingController(text: (widget.urun?.satisFiyati ?? 0).toString());
    _alisCtrl = TextEditingController(text: (widget.urun?.alisFiyati ?? 0).toString());
  }

  Future<void> _kaydet() async {
    if (!_formKey.currentState!.validate()) return;
    final map = {
      'kod': _kodCtrl.text.trim(),
      'ad': _adCtrl.text.trim(),
      'satis_fiyati': double.parse(_satisCtrl.text.replaceAll(',', '.')),
      'alis_fiyati': double.parse(_alisCtrl.text.replaceAll(',', '.')),
    };
    if (widget.urun == null) {
      await _db.urunEkle(map);
    } else {
      await _db.urunGuncelle(widget.urun!.id!, map);
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _sil() async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ürünü Sil'),
        content: Text('${widget.urun!.ad} silinsin mi? Tüm depolardaki stok kaydı da silinecek.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil')),
        ],
      ),
    );
    if (onay == true) {
      await _db.urunSil(widget.urun!.id!);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.urun == null ? 'Yeni Ürün' : 'Ürünü Düzenle'),
        actions: [
          if (widget.urun != null)
            IconButton(onPressed: _sil, icon: const Icon(Icons.delete_outline)),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _kodCtrl,
              decoration: const InputDecoration(labelText: 'Malzeme Kodu', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _adCtrl,
              decoration: const InputDecoration(labelText: 'Ürün Adı', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Ürün adı zorunlu' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _alisCtrl,
              decoration: const InputDecoration(labelText: 'Alış Fiyatı (₺)', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) =>
                  double.tryParse((v ?? '').replaceAll(',', '.')) == null ? 'Geçerli bir sayı girin' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _satisCtrl,
              decoration: const InputDecoration(labelText: 'Satış Fiyatı (₺)', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) =>
                  double.tryParse((v ?? '').replaceAll(',', '.')) == null ? 'Geçerli bir sayı girin' : null,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _kaydet,
              child: const Padding(padding: EdgeInsets.all(12), child: Text('Kaydet')),
            ),
          ],
        ),
      ),
    );
  }
}
