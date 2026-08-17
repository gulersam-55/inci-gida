import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/depo.dart';
import 'depo_detay_screen.dart';

class DepolarScreen extends StatefulWidget {
  const DepolarScreen({super.key});

  @override
  State<DepolarScreen> createState() => _DepolarScreenState();
}

class _DepolarScreenState extends State<DepolarScreen> {
  final _db = DatabaseHelper.instance;
  List<Depo> _depolar = [];

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    final rows = await _db.depolariGetir();
    setState(() => _depolar = rows.map((r) => Depo.fromMap(r)).toList());
  }

  Future<void> _yeniDepo() async {
    final ctrl = TextEditingController();
    final isim = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Yeni Depo'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Depo Adı (ör: Kavakdibi Depo)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: const Text('Ekle')),
        ],
      ),
    );
    if (isim != null && isim.isNotEmpty) {
      await _db.depoEkle(isim);
      _yukle();
    }
  }

  Future<void> _depoSil(Depo depo) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Depoyu Sil'),
        content: Text('${depo.isim} silinsin mi? Bu depodaki tüm stok kayıtları silinecek.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil')),
        ],
      ),
    );
    if (onay == true) {
      await _db.depoSil(depo.id!);
      _yukle();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Depolar')),
      body: _depolar.isEmpty
          ? const Center(child: Text('Henüz depo eklenmedi. Sağ alttan ekleyin.'))
          : ListView.builder(
              itemCount: _depolar.length,
              itemBuilder: (context, i) {
                final d = _depolar[i];
                return ListTile(
                  leading: const Icon(Icons.warehouse),
                  title: Text(d.isim),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _depoSil(d),
                  ),
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => DepoDetayScreen(depo: d))),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(onPressed: _yeniDepo, child: const Icon(Icons.add)),
    );
  }
}
