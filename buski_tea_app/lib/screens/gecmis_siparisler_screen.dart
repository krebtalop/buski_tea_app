import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';

class GecmisSiparislerScreen extends StatefulWidget {
  const GecmisSiparislerScreen({Key? key}) : super(key: key);

  @override
  State<GecmisSiparislerScreen> createState() => _GecmisSiparislerScreenState();
}

class _GecmisSiparislerScreenState extends State<GecmisSiparislerScreen> {
  // Kat bazlı personel sistemi
  List<String> _garsonlar = [];
  // Her sipariş için seçilen garsonu tutacak map
  final Map<String, String?> _secilenGarsonlar = {};

  String _filter = '1ay';
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _orders = [];
  bool _loading = true;
  double _totalSpent = 0;
  String? _errorMessage;
  String? _selectedOrderId;
  int _selectedRating = 0;
  bool _showRatingDialog = false;
  final TextEditingController _commentController = TextEditingController();

  // Pasta grafiği için değişkenler
  Map<String, double> _categoryData = {};
  Map<String, int> _categoryCounts = {}; // Her kategorinin sipariş sayısı
  String? _selectedCategory; // Seçili kategori
  // Dokunulan dilim indeksi
  List<Color> _pieColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.red,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
  ];

  // Sipariş kartlarının açık/kapalı durumunu takip etmek için
  final Map<String, bool> _expandedOrders = {};

  @override
  void initState() {
    super.initState();
    _loadPersonnel();
    _fetchOrders();
    _listenToPanelUpdates();
  }

  // Personel listesini yeniden yükle
  Future<void> _reloadPersonnel() async {
    print('DEBUG: Personel listesi yeniden yükleniyor...');
    await _loadPersonnel();
  }

  // Panel güncellemelerini dinle
  void _listenToPanelUpdates() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Panel siparişlerindeki değişiklikleri dinle
    FirebaseFirestore.instance
        .collection('siparisler')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
          // Panel'de değişiklik olduğunda siparişleri yeniden yükle
          if (mounted) {
            _fetchOrders();
          }
        });
  }

  Future<void> _loadPersonnel() async {
    try {
      // Kullanıcı verilerini al
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return;

      final userData = userDoc.data();
      print('DEBUG: Kullanıcı verileri: $userData');

      // Floor değerini güvenli şekilde al
      dynamic floorValue = userData?['floor'];
      int floor;

      if (floorValue is int) {
        floor = floorValue;
      } else if (floorValue is String) {
        floor = int.tryParse(floorValue) ?? 1;
      } else {
        floor = 1;
      }

      print('DEBUG: Floor değeri: $floor (tip: ${floorValue.runtimeType})');

      // Kat bazlı personel koleksiyonu belirle
      String personnelCollection = 'personel_z123'; // Varsayılan (Kat 1-2-3)
      if (floor >= 4 && floor <= 6) {
        personnelCollection = 'personel_456'; // Kat 4-5-6
      } else if (floor >= 7 && floor <= 10) {
        personnelCollection = 'personel_78910'; // Kat 7-8-9-10
      }

      print(
        'Kullanıcı katı: $floor, Personel koleksiyonu: $personnelCollection',
      );

      // Personeli Firebase'den yükle
      print('DEBUG: Firebase\'e bağlanıyor - Koleksiyon: $personnelCollection');

      final personnelSnapshot = await FirebaseFirestore.instance
          .collection(personnelCollection)
          .get();

      print('DEBUG: Gelen doküman sayısı: ${personnelSnapshot.docs.length}');

      final personnel = <String>[];
      for (var doc in personnelSnapshot.docs) {
        final data = doc.data();
        print('DEBUG: Personel verisi: $data');
        final name = '${data['ad']} ${data['soyad']}';
        personnel.add(name);
        print('DEBUG: Eklenen personel: $name');
      }

      setState(() {
        _garsonlar = personnel;
      });

      print('DEBUG: Toplam yüklenen personel: $_garsonlar');

      if (personnel.isEmpty) {
        print('DEBUG: PERSONEL LİSTESİ BOŞ!');
        print('DEBUG: Kullanıcı katı: $floor');
        print('DEBUG: Kullanılan koleksiyon: $personnelCollection');
        print(
          'DEBUG: Firebase\'den gelen doküman sayısı: ${personnelSnapshot.docs.length}',
        );
      }
    } catch (error) {
      print('DEBUG: Personel yüklenirken hata: $error');
      setState(() {
        _garsonlar = [];
      });
    }
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
      });
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

      // Panel'den güncel siparişleri al (durum bilgisi dahil)
      final panelOrdersSnapshot = await FirebaseFirestore.instance
          .collection('siparisler')
          .where('userId', isEqualTo: user.uid)
          .where('tarih', isGreaterThan: Timestamp.fromDate(startDate))
          .orderBy('tarih', descending: true)
          .get();

      // Kullanıcının geçmiş siparişlerini de al
      final userOrdersSnapshot = await FirebaseFirestore.instance
          .collection('user_orders')
          .doc(user.uid)
          .collection('orders')
          .get();

      // Kullanıcı geçmişinde olan sipariş ID'lerini al
      final userOrderIds = userOrdersSnapshot.docs.map((doc) => doc.id).toSet();

      // Panel siparişlerini filtrele - sadece kullanıcı geçmişinde olanları göster
      _orders = panelOrdersSnapshot.docs
          .where((doc) => userOrderIds.contains(doc.id))
          .toList();

      _totalSpent = 0;
      _categoryData.clear();
      _categoryCounts.clear();

      for (var doc in _orders) {
        final data = doc.data();
        _totalSpent += (data['toplamFiyat'] ?? 0).toDouble();

        // Kategori verilerini hesapla
        final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
        for (var item in items) {
          final category = item['name'] ?? 'Diğer';
          final price = (item['price'] ?? 0).toDouble() * (item['adet'] ?? 1);
          final int adet = (item['adet'] ?? 1).toInt();

          _categoryData[category] = (_categoryData[category] ?? 0) + price;
          final currentCount = _categoryCounts[category] ?? 0;
          _categoryCounts[category] = currentCount + adet;
        }
      }

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = 'Siparişler yüklenemedi: $e';
      });
    }
  }

  // Tek sipariş sil
  Future<void> _deleteSingleOrder(String orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Siparişi Sil'),
          content: const Text(
            'Bu siparişi geçmişinizden silmek istediğinizden emin misiniz?\n\n'
            'Bu işlem sadece uygulama ekranından siparişi kaldırır. '
            'Panel tarafından kontrol edilen sipariş etkilenmez.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sil', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Sadece kullanıcı geçmişinden sil
      await FirebaseFirestore.instance
          .collection('user_orders')
          .doc(user.uid)
          .collection('orders')
          .doc(orderId)
          .delete();

      // Siparişleri yeniden yükle
      await _fetchOrders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sipariş geçmişinizden silindi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sipariş silinirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Tüm siparişleri sil (sadece kullanıcı geçmişinden)
  Future<void> _clearAllOrders() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Siparişleri Sil'),
          content: const Text(
            'Tüm sipariş geçmişinizi silmek istediğinizden emin misiniz?\n\n'
            'Bu işlem sadece uygulama ekranından siparişleri kaldırır. '
            'Panel tarafından kontrol edilen siparişler etkilenmez.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sil', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Kullanıcının tüm siparişlerini al
      final snapshot = await FirebaseFirestore.instance
          .collection('user_orders')
          .doc(user.uid)
          .collection('orders')
          .get();

      if (snapshot.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Silinecek sipariş bulunamadı'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Batch işlemi ile tüm siparişleri sil
      final batch = FirebaseFirestore.instance.batch();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      // Siparişleri yeniden yükle
      await _fetchOrders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${snapshot.docs.length} sipariş geçmişi başarıyla silindi',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Siparişler silinirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Pasta grafiği widget'ı
  Widget _buildPieChart() {
    if (_categoryData.isEmpty) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pie_chart_outline, size: 32, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'Henüz sipariş verisi yok',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final pieChartSections = <PieChartSectionData>[];
    final categories = _categoryData.keys.toList();

    for (int i = 0; i < categories.length; i++) {
      final category = categories[i];
      final value = _categoryData[category]!;
      final isSelected = _selectedCategory == category;

      pieChartSections.add(
        PieChartSectionData(
          color: _pieColors[i % _pieColors.length],
          value: value,
          title: '', // Başlık yok
          radius: isSelected ? 45 : 35, // Seçili olan büyük
          borderSide: isSelected
              ? const BorderSide(color: Colors.white, width: 2)
              : BorderSide.none,
        ),
      );
    }

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Kategori Dağılımı',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),
          // Pasta grafiği
          SizedBox(
            height: 140,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = null;
                });
              },
              child: PieChart(
                PieChartData(
                  sections: pieChartSections,
                  centerSpaceRadius: 25,
                  sectionsSpace: 1,
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      if (event is! FlPointerHoverEvent &&
                          pieTouchResponse?.touchedSection != null) {
                        final touchedIndex = pieTouchResponse!
                            .touchedSection!
                            .touchedSectionIndex;
                        final category = categories[touchedIndex];
                        setState(() {
                          _selectedCategory = _selectedCategory == category
                              ? null
                              : category;
                        });
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
          // Seçili kategori bilgisi
          if (_selectedCategory != null) ...[
            const SizedBox(height: 8),
            Text(
              '$_selectedCategory: ${_categoryCounts[_selectedCategory] ?? 0} adet',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1565C0),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Siparişi tekrarla
  Future<void> _repeatOrder(Map<String, dynamic> orderData) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final items = List<Map<String, dynamic>>.from(orderData['items'] ?? []);
      if (items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sipariş içeriği bulunamadı!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Kullanıcı profil bilgilerini al
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDoc.data() ?? {};

      // Yeni sipariş oluştur
      final newOrder = {
        'userId': user.uid,
        'userName': user.displayName ?? userData['name'] ?? 'Kullanıcı',
        'floor': orderData['floor'],
        'items': items,
        'toplamFiyat': orderData['toplamFiyat'],
        'tarih': Timestamp.now(),
        'status': 'hazırlanıyor',
        'isRepeated': true,
        'originalOrderId': orderData['id'] ?? '',
      };

      // Siparişi hem panel koleksiyonuna hem de kullanıcı geçmişine kaydet
      final orderRef = await FirebaseFirestore.instance
          .collection('siparisler')
          .add(newOrder);

      await FirebaseFirestore.instance
          .collection('user_orders')
          .doc(user.uid)
          .collection('orders')
          .doc(orderRef.id)
          .set({...newOrder, 'id': orderRef.id});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Siparişiniz tekrarlandı!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sipariş tekrarlanırken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Puanlama modalını göster
  void _showRatingModal(String orderId, Map<String, dynamic> orderData) {
    // Sadece teslim edilmiş siparişler için puanlama yapılabilir
    final status = orderData['status'] ?? 'hazırlanıyor';
    if (status.toLowerCase() != 'teslim edildi') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sadece teslim edilmiş siparişler puanlanabilir!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _selectedOrderId = orderId;
    _selectedRating = orderData['rating'] ?? 0;
    _commentController.text = orderData['comment'] ?? '';
    setState(() {
      _showRatingDialog = true;
    });
  }

  // Puanlama kaydet
  Future<void> _saveRating() async {
    if (_selectedOrderId == null) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final updateData = {
        'rating': _selectedRating,
        'ratingDate': Timestamp.now(),
        'comment': _commentController.text.trim(),
        'garson': _secilenGarsonlar[_selectedOrderId],
      };

      await Future.wait([
        FirebaseFirestore.instance
            .collection('siparisler')
            .doc(_selectedOrderId)
            .update(updateData),
        FirebaseFirestore.instance
            .collection('user_orders')
            .doc(user.uid)
            .collection('orders')
            .doc(_selectedOrderId)
            .update(updateData),
      ]);

      await _fetchOrders();

      setState(() {
        _showRatingDialog = false;
        _selectedOrderId = null;
        _selectedRating = 0;
        _commentController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Puanınız kaydedildi!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Puanlama kaydedilirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Durum widget'ı
  Widget _buildStatusWidget(String status) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status.toLowerCase()) {
      case 'hazırlanıyor':
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
        statusText = 'Hazırlanıyor';
        break;
      case 'teslim edildi':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Teslim Edildi';
        break;
      default:
        statusColor = Colors.blue;
        statusIcon = Icons.help_outline;
        statusText = 'Hazırlandı';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 16, color: statusColor),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  // Yıldız widget'ı
  Widget _buildStarRating(int rating, Function(int) onRatingChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: () => onRatingChanged(index + 1),
          child: Icon(
            index < rating ? Icons.star : Icons.star_border,
            color: index < rating ? Colors.amber : Colors.grey,
            size: 40,
          ),
        );
      }),
    );
  }

  // Puanlama modalı
  Widget _buildRatingModal() {
    if (!_showRatingDialog || _selectedOrderId == null) {
      return const SizedBox.shrink();
    }

    final orderData = _orders
        .firstWhere((doc) => doc.id == _selectedOrderId)
        .data();
    final tarih = (orderData['tarih'] as Timestamp).toDate();
    final items = List<Map<String, dynamic>>.from(orderData['items'] ?? []);

    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Sipariş Değerlendirmesi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _showRatingDialog = false;
                        _selectedOrderId = null;
                        _selectedRating = 0;
                        _commentController.clear();
                      });
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tarih: ${tarih.day.toString().padLeft(2, '0')}.${tarih.month.toString().padLeft(2, '0')}.${tarih.year}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('Toplam: ${orderData['toplamFiyat']} TL'),
                    const SizedBox(height: 8),
                    const Text(
                      'Sipariş İçeriği:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...items.map(
                      (item) => Text(
                        '• ${item['name']} ${item['option'] != null && item['option'] != '' ? '(${item['option']})' : ''} x${item['adet']}',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Bu siparişi nasıl değerlendirirsiniz?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              _buildStarRating(_selectedRating, (rating) {
                setState(() {
                  _selectedRating = rating;
                });
              }),
              const SizedBox(height: 8),
              Text(
                _selectedRating == 0
                    ? 'Puanlama yapın'
                    : _selectedRating == 1
                    ? 'Çok Kötü'
                    : _selectedRating == 2
                    ? 'Kötü'
                    : _selectedRating == 3
                    ? 'Orta'
                    : _selectedRating == 4
                    ? 'İyi'
                    : 'Mükemmel',
                style: TextStyle(
                  fontSize: 14,
                  color: _selectedRating == 0 ? Colors.grey : Colors.blue[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              // Garson seçimi dropdown'u
              Container(
                width: double.infinity,
                child: DropdownButtonFormField<String>(
                  value: _secilenGarsonlar[_selectedOrderId],
                  decoration: const InputDecoration(
                    labelText: 'Siparişi getiren garson',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                  ),
                  items: _garsonlar.map((String garson) {
                    return DropdownMenuItem<String>(
                      value: garson,
                      child: Text(garson),
                    );
                  }).toList(),
                  onChanged: (String? yeniGarson) {
                    setState(() {
                      _secilenGarsonlar[_selectedOrderId!] = yeniGarson;
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),
              // Yorum alanı
              Container(
                width: double.infinity,
                child: TextField(
                  controller: _commentController,
                  maxLines: 3,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    hintText:
                        'Siparişiniz hakkında yorum yazın (isteğe bağlı)...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedRating > 0 ? _saveRating : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Puanı Kaydet'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_selectedOrderId == null) return;
                        try {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) return;
                          final updateData = {
                            'rating': 0,
                            'comment': '',
                            'ratingDate': null,
                            'garson': null,
                          };
                          await Future.wait([
                            FirebaseFirestore.instance
                                .collection('siparisler')
                                .doc(_selectedOrderId)
                                .update(updateData),
                            FirebaseFirestore.instance
                                .collection('user_orders')
                                .doc(user.uid)
                                .collection('orders')
                                .doc(_selectedOrderId)
                                .update(updateData),
                          ]);
                          await _fetchOrders();
                          setState(() {
                            _showRatingDialog = false;
                            _selectedOrderId = null;
                            _selectedRating = 0;
                            _commentController.clear();
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Puanınız kaldırıldı.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Puan kaldırılırken hata oluştu: $e',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Temizle'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geçmiş Siparişlerim'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => _clearAllOrders(),
            tooltip: 'Tüm Siparişleri Sil',
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1565C0),
                  Color(0xFF42A5F5),
                  Color(0xFFB3E5FC),
                ],
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
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : _orders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.info_outline,
                          size: 64,
                          color: Colors.white70,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Hiç siparişiniz bulunamadı.',
                          style: TextStyle(fontSize: 18, color: Colors.white70),
                        ),
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
                                setState(() {
                                  _filter = '1hafta';
                                });
                                _fetchOrders();
                              },
                            ),
                            const SizedBox(width: 12),
                            FilterChip(
                              label: const Text('Son 1 Ay'),
                              selected: _filter == '1ay',
                              onSelected: (v) {
                                setState(() {
                                  _filter = '1ay';
                                });
                                _fetchOrders();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        // Pasta grafiği
                        _buildPieChart(),
                        const SizedBox(height: 18),
                        // Toplam harcama
                        Card(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Toplam Harcama',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1565C0),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${_totalSpent.toStringAsFixed(2)} TL',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        // Sipariş Listesi
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Tüm Siparişler',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF003366),
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
                            final items = List<Map<String, dynamic>>.from(
                              data['items'] ?? [],
                            );
                            final rating = data['rating'] ?? 0;
                            final comment = data['comment'] ?? '';
                            final garson = data['garson'] ?? '';
                            final status = data['status'] ?? 'hazırlanıyor';
                            final orderId = _orders[i].id;
                            final isExpanded =
                                _expandedOrders[orderId] ?? false;

                            return Card(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: Column(
                                children: [
                                  // Ana sipariş bilgileri (her zaman görünür)
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${tarih.day.toString().padLeft(2, '0')}.${tarih.month.toString().padLeft(2, '0')}.${tarih.year}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF1565C0),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                _buildStatusWidget(status),
                                              ],
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  '${data['toplamFiyat']} TL',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Sipariş Saati: ${tarih.hour.toString().padLeft(2, '0')}:${tarih.minute.toString().padLeft(2, '0')}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        // Dropdown butonu
                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              _expandedOrders[orderId] =
                                                  !isExpanded;
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue[50],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.blue[200]!,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'Sipariş İçeriği (${items.length} ürün)',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.blue[700],
                                                  ),
                                                ),
                                                Icon(
                                                  isExpanded
                                                      ? Icons.keyboard_arrow_up
                                                      : Icons
                                                            .keyboard_arrow_down,
                                                  color: Colors.blue[700],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Genişletilmiş içerik (sadece açıkken görünür)
                                  if (isExpanded) ...[
                                    Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: const BorderRadius.only(
                                          bottomLeft: Radius.circular(12),
                                          bottomRight: Radius.circular(12),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Sipariş ürünleri
                                            ...items.map(
                                              (item) => Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 2.0,
                                                    ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        '${item['name']} ${item['option'] != null && item['option'] != '' ? '(${item['option']})' : ''}',
                                                        style: const TextStyle(
                                                          fontSize: 15,
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      'x${item['adet']}',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            // Garson bilgisi gösterimi
                                            if (garson.isNotEmpty) ...[
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.green[50],
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: Colors.green[200]!,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.person,
                                                      size: 16,
                                                      color: Colors.green[700],
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Garson: $garson',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color:
                                                            Colors.green[700],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                            ],
                                            // Yorum gösterimi
                                            if (comment.isNotEmpty) ...[
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue[50],
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: Colors.blue[200]!,
                                                  ),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      'Yorumunuz:',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.blue,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      comment,
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                            ],
                                            // Puanlama ve tekrarlama bölümü
                                            Column(
                                              children: [
                                                // Puanlama gösterimi (varsa)
                                                if (rating > 0) ...[
                                                  Row(
                                                    children: [
                                                      const Text(
                                                        'Puanınız: ',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                      Row(
                                                        children: List.generate(
                                                          5,
                                                          (index) {
                                                            return Icon(
                                                              index < rating
                                                                  ? Icons.star
                                                                  : Icons
                                                                        .star_border,
                                                              color:
                                                                  index < rating
                                                                  ? Colors.amber
                                                                  : Colors.grey,
                                                              size: 20,
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 12),
                                                ],
                                                // Butonlar yan yana
                                                Row(
                                                  children: [
                                                    // Puanla butonu (sadece teslim edilmiş siparişler için)
                                                    if (status.toLowerCase() ==
                                                        'teslim edildi') ...[
                                                      Expanded(
                                                        child: ElevatedButton.icon(
                                                          onPressed: () =>
                                                              _showRatingModal(
                                                                _orders[i].id,
                                                                data,
                                                              ),
                                                          icon: const Icon(
                                                            Icons.rate_review,
                                                            size: 16,
                                                          ),
                                                          label: Text(
                                                            rating > 0
                                                                ? 'Puanla'
                                                                : 'Puanla',
                                                          ),
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor:
                                                                rating > 0
                                                                ? Colors.orange
                                                                : Colors
                                                                      .blue[700],
                                                            foregroundColor:
                                                                Colors.white,
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      12,
                                                                  vertical: 8,
                                                                ),
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    6,
                                                                  ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                    ],
                                                    // Tekrarlama butonu
                                                    Expanded(
                                                      child: ElevatedButton.icon(
                                                        onPressed: () =>
                                                            _repeatOrder(data),
                                                        icon: const Icon(
                                                          Icons.replay,
                                                          size: 16,
                                                        ),
                                                        label: const Text(
                                                          'Tekrarla',
                                                        ),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.green[600],
                                                          foregroundColor:
                                                              Colors.white,
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 12,
                                                                vertical: 8,
                                                              ),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  6,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    // Silme butonu
                                                    Expanded(
                                                      child: ElevatedButton.icon(
                                                        onPressed: () =>
                                                            _deleteSingleOrder(
                                                              _orders[i].id,
                                                            ),
                                                        icon: const Icon(
                                                          Icons.delete,
                                                          size: 16,
                                                        ),
                                                        label: const Text(
                                                          'Sil',
                                                        ),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.red[600],
                                                          foregroundColor:
                                                              Colors.white,
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 12,
                                                                vertical: 8,
                                                              ),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  6,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
          ),
          // Puanlama modalı
          if (_showRatingDialog) _buildRatingModal(),
        ],
      ),
    );
  }
}