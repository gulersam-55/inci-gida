import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/kasa_kaydi.dart';
import 'kasa_form_screen.dart';

class KasaScreen extends StatefulWidget {
  const KasaScreen({super.key});

  @override
  State<KasaScreen> createState() => _KasaScreenState();
}

class _KasaScreenState extends State<KasaScreen> {
  final _db = DatabaseHelper.instance;
  List<KasaKaydi> _kayitlar = [];
  final _fmt = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
  final _tarihFmt = DateFormat('dd.MM.yyyy');

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    final rows = await _db.kasaKayitlariGetir();
    setState(() => _kayitlar = rows.map((r) => KasaKaydi.fromMap(r)).toList());
  }

  double get _toplam => _kayitlar.fold(0.0, (t, k) => t + k.tutar);

  Future<void> _sil(KasaKaydi k) async {
    await _db.kasaKaydiSil(k.id!);
    _yukle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kasa')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: _toplam >= 0 ? Colors.green.shade100 : Colors.red.shade100,
            padding: const EdgeInsets.all(16),
            child: Text('Kasa Bakiyesi: ${_fmt.format(_toplam)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Expanded(
            child: _kayitlar.isEmpty
                ? const Center(child: Text('Henüz kasa kaydı yok. Sağ alttan ekleyin.'))
                : ListView.builder(
                    itemCount: _kayitlar.length,
                    itemBuilder: (context, i) {
                      final k = _kayitlar[i];
                      final renk = k.tutar >= 0 ? Colors.green : Colors.red;
                      return Dismissible(
                        key: ValueKey(k.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => _sil(k),
                        child: ListTile(
                          title: Text(k.kalemAdi),
                          subtitle: Text(_tarihFmt.format(k.tarih) +
                              (k.aciklama != null && k.aciklama!.isNotEmpty ? ' • ${k.aciklama}' : '')),
                          trailing: Text(_fmt.format(k.tutar),
                              style: TextStyle(color: renk, fontWeight: FontWeight.bold)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const KasaFormScreen()));
          _yukle();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
