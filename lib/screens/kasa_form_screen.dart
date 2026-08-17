import 'package:flutter/material.dart';
import '../db/database_helper.dart';

class KasaFormScreen extends StatefulWidget {
  const KasaFormScreen({super.key});

  @override
  State<KasaFormScreen> createState() => _KasaFormScreenState();
}

class _KasaFormScreenState extends State<KasaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _kalemCtrl = TextEditingController();
  final _tutarCtrl = TextEditingController();
  final _aciklamaCtrl = TextEditingController();
  DateTime _tarih = DateTime.now();
  bool _gider = true; // true: gider (kasadan çıkar), false: gelir (kasaya girer)
  final _db = DatabaseHelper.instance;
  List<String> _oneriler = [];

  @override
  void initState() {
    super.initState();
    _onerileriYukle();
  }

  Future<void> _onerileriYukle() async {
    final list = await _db.kasaKalemAdlariGetir();
    setState(() => _oneriler = list);
  }

  Future<void> _tarihSec() async {
    final secilen = await showDatePicker(
      context: context,
      initialDate: _tarih,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (secilen != null) setState(() => _tarih = secilen);
  }

  Future<void> _kaydet() async {
    if (!_formKey.currentState!.validate()) return;
    final tutarMutlak =
        double.parse(_tutarCtrl.text.replaceAll(',', '.').replaceAll('-', ''));
    final tutar = _gider ? -tutarMutlak : tutarMutlak;
    final map = {
      'tarih': _tarih.toIso8601String(),
      'kalem_adi': _kalemCtrl.text.trim(),
      'tutar': tutar,
      'aciklama': _aciklamaCtrl.text.trim().isEmpty ? null : _aciklamaCtrl.text.trim(),
    };
    await _db.kasaKaydiEkle(map);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Kasa Kaydı')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tarih'),
              subtitle: Text('${_tarih.day}.${_tarih.month}.${_tarih.year}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _tarihSec,
            ),
            const SizedBox(height: 8),
            Autocomplete<String>(
              optionsBuilder: (v) => v.text.isEmpty
                  ? _oneriler
                  : _oneriler.where((o) => o.toLowerCase().contains(v.text.toLowerCase())),
              onSelected: (v) => _kalemCtrl.text = v,
              fieldViewBuilder: (context, ctrl, focus, onSubmit) {
                ctrl.text = _kalemCtrl.text;
                return TextFormField(
                  controller: ctrl,
                  focusNode: focus,
                  decoration: const InputDecoration(
                    labelText: 'Kalem Adı (ör: Yakıt, Yemek Gideri, Nakit)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => _kalemCtrl.text = v,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Kalem adı zorunlu' : null,
                );
              },
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Gider')),
                ButtonSegment(value: false, label: Text('Gelir')),
              ],
              selected: {_gider},
              onSelectionChanged: (s) => setState(() => _gider = s.first),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tutarCtrl,
              decoration: const InputDecoration(labelText: 'Tutar (₺)', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) =>
                  double.tryParse((v ?? '').replaceAll(',', '.').replaceAll('-', '')) == null
                      ? 'Geçerli bir sayı girin'
                      : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _aciklamaCtrl,
              decoration: const InputDecoration(labelText: 'Açıklama (opsiyonel)', border: OutlineInputBorder()),
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
