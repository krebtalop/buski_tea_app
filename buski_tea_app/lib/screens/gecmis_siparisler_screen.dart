import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'package:flutter/cupertino.dart';

class GecmisSiparislerScreen extends StatefulWidget {
  const GecmisSiparislerScreen({Key? key}) : super(key: key);

  @override
  State<GecmisSiparislerScreen> createState() => _GecmisSiparislerScreenState();
}

class _GecmisSiparislerScreenState extends State<GecmisSiparislerScreen> {
  String _filter = '1ay';
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _orders = [];
  bool _loading = true;
  double _totalSpent = 0;
  Map<String, int> _productCounts = {};
  String? _errorMessage;
  int? _touchedIndex;
  String? _selectedProduct;
  int? _selectedProductCount;
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() { _loading = true; _errorMessage = null; });
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() { _loading = false; });
      return;
    }
    try {
      final now = DateTime.now();
      DateTime startDate;
      if (_filter == '1hafta') {
        startDate = now.subtract(const Duration(days: 7));
      } else {
        startDate = now.subtract(const Duration(days: 30));
      }
      final snapshot = await FirebaseFirestore.instance
          .collection('siparisler')
          .where('userId', isEqualTo: user.uid)
          .where('tarih', isGreaterThan: Timestamp.fromDate(startDate))
          .orderBy('tarih', descending: true)
          .get();
      _orders = snapshot.docs;
      _totalSpent = 0;
      _productCounts = {};
      for (var doc in _orders) {
        final data = doc.data();
        _totalSpent += (data['toplamFiyat'] ?? 0).toDouble();
        final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
        for (var item in items) {
          final name = item['name'] ?? 'Ürün';
          int adet = 1;
          if (item['adet'] != null) {
            if (item['adet'] is int) {
              adet = item['adet'];
            } else if (item['adet'] is num) {
              adet = (item['adet'] as num).toInt();
            } else if (item['adet'] is String) {
              adet = int.tryParse(item['adet']) ?? 1;
            }
          }
          _productCounts[name] = (_productCounts[name] ?? 0) + adet;
        }
      }
      setState(() { _loading = false; });
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = 'Siparişler yüklenemedi: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Siparişleri gün gün grupla
    Map<String, List<Map<String, dynamic>>> groupedOrders = {};
    for (var doc in _orders) {
      final data = doc.data();
      final tarih = (data['tarih'] as Timestamp).toDate();
      final dayKey = '${tarih.year}-${tarih.month.toString().padLeft(2, '0')}-${tarih.day.toString().padLeft(2, '0')}';
      groupedOrders.putIfAbsent(dayKey, () => []).add(data);
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geçmiş Siparişlerim'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1565C0), Color(0xFF42A5F5), Color(0xFFB3E5FC)],
          ),
        ),
        width: double.infinity,
        height: double.infinity,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                        const SizedBox(height: 16),
                        Text(_errorMessage!, style: const TextStyle(fontSize: 16, color: Colors.white), textAlign: TextAlign.center),
                      ],
                    ),
                  )
                : _orders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.info_outline, size: 64, color: Colors.white70),
                        SizedBox(height: 16),
                        Text('Hiç siparişiniz bulunamadı.', style: TextStyle(fontSize: 18, color: Colors.white70)),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                    // Filtre butonları
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FilterChip(
                          label: const Text('Son 1 Hafta'),
                          selected: _filter == '1hafta',
                          onSelected: (v) {
                            setState(() { _filter = '1hafta'; });
                            _fetchOrders();
                          },
                        ),
                        const SizedBox(width: 12),
                        FilterChip(
                          label: const Text('Son 1 Ay'),
                          selected: _filter == '1ay',
                          onSelected: (v) {
                            setState(() { _filter = '1ay'; });
                            _fetchOrders();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // Toplam harcama
                    Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Column(
                          children: [
                            const Text('Toplam Harcama', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                            const SizedBox(height: 6),
                            Text('${_totalSpent.toStringAsFixed(2)} TL', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Pasta Grafik
                    if (_productCounts.isNotEmpty)
                      Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 200,
                                child: PieChart(
                                  PieChartData(
                                    sections: _productCounts.entries.map((e) {
                                      final idx = _productCounts.keys.toList().indexOf(e.key);
                                      final color = Colors.primaries[idx % Colors.primaries.length];
                                      final isTouched = _touchedIndex == idx;
                                      return PieChartSectionData(
                                        color: color,
                                        value: e.value.toDouble(),
                                        title: '',
                                        radius: isTouched ? 70 : 60,
                                        titleStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                        titlePositionPercentageOffset: 0.6,
                                      );
                                    }).toList(),
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 30,
                                    pieTouchData: PieTouchData(
                                      touchCallback: (event, response) {
                                        if (response != null && response.touchedSection != null) {
                                          setState(() {
                                            _touchedIndex = response.touchedSection!.touchedSectionIndex;
                                            final key = _productCounts.keys.toList()[_touchedIndex!];
                                            _selectedProduct = key;
                                            _selectedProductCount = _productCounts[key];
                                          });
                                        } else {
                                          setState(() {
                                            _touchedIndex = null;
                                            _selectedProduct = null;
                                            _selectedProductCount = null;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (_selectedProduct != null && _selectedProductCount != null)
                                Text(
                                  '${_selectedProduct!}: $_selectedProductCount adet',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
                                ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 18),
                    // Sipariş Listesi (trendyol tarzı, expandable)
                    const SizedBox(height: 18),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Tüm Siparişler',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003366), // Daha koyu ve belirgin mavi
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _orders.length,
                      itemBuilder: (context, i) {
                        final data = _orders[i].data();
                        final tarih = (data['tarih'] as Timestamp).toDate();
                        final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
                        return Card(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              setState(() {
                                _expandedIndex = _expandedIndex == i ? null : i;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${tarih.day.toString().padLeft(2, '0')}.${tarih.month.toString().padLeft(2, '0')}.${tarih.year}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            '${data['toplamFiyat']} TL',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            _expandedIndex == i ? 'Detayı Gizle' : 'Detayı Gör',
                                            style: const TextStyle(fontSize: 14, color: Color(0xFF1565C0), fontWeight: FontWeight.w500),
                                          ),
                                          Icon(_expandedIndex == i ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down, color: Color(0xFF1565C0), size: 18),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (_expandedIndex == i) ...[
                                    const Divider(height: 18, thickness: 1, color: Color(0xFFB3E5FC)),
                                    ...items.map((item) => Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('${item['name']} ${item['option'] != null && item['option'] != '' ? '(${item['option']})' : ''}', style: const TextStyle(fontSize: 15)),
                                              Text('x${item['adet']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                        )),
                                    const SizedBox(height: 4),
                                    Text('Sipariş Saati: ${tarih.hour.toString().padLeft(2, '0')}:${tarih.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 14, color: Colors.black54)),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }
} 