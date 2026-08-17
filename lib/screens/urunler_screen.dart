import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/urun.dart';
import 'urun_form_screen.dart';

class UrunlerScreen extends StatefulWidget {
  const UrunlerScreen({super.key});

  @override
  State<UrunlerScreen> createState() => _UrunlerScreenState();
}

class _UrunlerScreenState extends State<UrunlerScreen> {
  final _db = DatabaseHelper.instance;
  List<Urun> _urunler = [];
  String _arama = '';
  final _fmt = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    final rows = await _db.urunleriGetir();
    setState(() => _urunler = rows.map((r) => Urun.fromMap(r)).toList());
  }

  @override
  Widget build(BuildContext context) {
    final filtreli = _urunler
        .where((u) =>
            u.ad.toLowerCase().contains(_arama.toLowerCase()) ||
            u.kod.toLowerCase().contains(_arama.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Ürünler')),
      body: Column(
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
                ? const Center(child: Text('Ürün bulunamadı. Sağ alttan yeni ürün ekleyin.'))
                : ListView.builder(
                    itemCount: filtreli.length,
                    itemBuilder: (context, i) {
                      final u = filtreli[i];
                      final karRenk = u.karTL >= 0 ? Colors.green : Colors.red;
                      return ListTile(
                        title: Text(u.ad),
                        subtitle: Text(
                            'Kod: ${u.kod.isEmpty ? "-" : u.kod}  •  Alış: ${_fmt.format(u.alisFiyati)}  •  Satış: ${_fmt.format(u.satisFiyati)}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(_fmt.format(u.karTL),
                                style: TextStyle(color: karRenk, fontWeight: FontWeight.bold)),
                            Text('%${u.karYuzde.toStringAsFixed(1)}',
                                style: TextStyle(color: karRenk, fontSize: 12)),
                          ],
                        ),
                        onTap: () async {
                          await Navigator.push(
                              context, MaterialPageRoute(builder: (_) => UrunFormScreen(urun: u)));
                          _yukle();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const UrunFormScreen()));
          _yukle();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
