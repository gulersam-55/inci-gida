import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';

class GenelToplamScreen extends StatefulWidget {
  const GenelToplamScreen({super.key});

  @override
  State<GenelToplamScreen> createState() => _GenelToplamScreenState();
}

class _GenelToplamScreenState extends State<GenelToplamScreen> {
  final _db = DatabaseHelper.instance;
  List<Map<String, dynamic>> _veriler = [];
  final _fmt = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    final list = await _db.genelToplamGetir();
    setState(() => _veriler = list);
  }

  double get _genelToplam =>
      _veriler.fold(0.0, (t, s) => t + (s['toplam_miktar'] as num) * (s['alis_fiyati'] as num));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Genel Toplam'),
        actions: [IconButton(onPressed: _yukle, icon: const Icon(Icons.refresh))],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.primaryContainer,
            padding: const EdgeInsets.all(16),
            child: Text('Tüm Depolar Toplam Değeri: ${_fmt.format(_genelToplam)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Expanded(
            child: _veriler.isEmpty
                ? const Center(child: Text('Veri yok'))
                : ListView.builder(
                    itemCount: _veriler.length,
                    itemBuilder: (context, i) {
                      final v = _veriler[i];
                      final miktar = v['toplam_miktar'] as num;
                      final toplam = miktar * (v['alis_fiyati'] as num);
                      final kod = v['kod'] as String?;
                      return ListTile(
                        title: Text(v['ad'] as String),
                        subtitle: Text('Kod: ${(kod == null || kod.isEmpty) ? "-" : kod}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('$miktar adet', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(_fmt.format(toplam), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
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
