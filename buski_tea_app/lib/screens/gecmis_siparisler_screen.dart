import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

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
  String? _errorMessage;
  String? _selectedOrderId;
  int _selectedRating = 0;
  bool _showRatingDialog = false;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchOrders();
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

      final snapshot = await FirebaseFirestore.instance
          .collection('user_orders')
          .doc(user.uid)
          .collection('orders')
          .where('tarih', isGreaterThan: Timestamp.fromDate(startDate))
          .orderBy('tarih', descending: true)
          .get();

      _orders = snapshot.docs;
      _totalSpent = 0;
      
      for (var doc in _orders) {
        final data = doc.data();
        _totalSpent += (data['toplamFiyat'] ?? 0).toDouble();
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

  // Tüm yorumları sil
  Future<void> _clearAllComments() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tüm Yorumları Sil'),
          content: const Text('Tüm yorumlarınızı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'),
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

      // Batch işlemi ile tüm yorumları sil
      final batch = FirebaseFirestore.instance.batch();
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['comment'] != null && data['comment'].toString().isNotEmpty) {
          batch.update(doc.reference, {
            'comment': '',
          });
        }
      }

      await batch.commit();

      // Siparişleri yeniden yükle
      await _fetchOrders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tüm yorumlar başarıyla silindi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yorumlar silinirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
          .set({
        ...newOrder,
        'id': orderRef.id,
      });

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
              // Yorum alanı
              Container(
                width: double.infinity,
                child: TextField(
                  controller: _commentController,
                  maxLines: 3,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    hintText: 'Siparişiniz hakkında yorum yazın (isteğe bağlı)...',
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
              SizedBox(
                width: double.infinity,
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
            onPressed: _clearAllComments,
            tooltip: 'Tüm Yorumları Sil',
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

                            return Card(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${tarih.day.toString().padLeft(2, '0')}.${tarih.month.toString().padLeft(2, '0')}.${tarih.year}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1565C0),
                                          ),
                                        ),
                                        Text(
                                          '${data['toplamFiyat']} TL',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ...items.map(
                                      (item) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${item['name']} ${item['option'] != null && item['option'] != '' ? '(${item['option']})' : ''}',
                                              style: const TextStyle(fontSize: 15),
                                            ),
                                            Text(
                                              'x${item['adet']}',
                                              style: const TextStyle(fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Sipariş Saati: ${tarih.hour.toString().padLeft(2, '0')}:${tarih.minute.toString().padLeft(2, '0')}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    // Yorum gösterimi
                                    if (comment.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[50],
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.blue[200]!),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Yorumunuz:',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
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
                                    ],
                                    const SizedBox(height: 12),
                                    // Puanlama ve tekrarlama bölümü
                                    Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                const Text(
                                                  'Puanınız: ',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                Row(
                                                  children: List.generate(5, (index) {
                                                    return Icon(
                                                      index < rating
                                                          ? Icons.star
                                                          : Icons.star_border,
                                                      color: index < rating
                                                          ? Colors.amber
                                                          : Colors.grey,
                                                      size: 20,
                                                    );
                                                  }),
                                                ),
                                                if (rating > 0) ...[
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    '($rating/5)',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            ElevatedButton.icon(
                                              onPressed: () => _showRatingModal(
                                                _orders[i].id,
                                                data,
                                              ),
                                              icon: const Icon(
                                                Icons.rate_review,
                                                size: 16,
                                              ),
                                              label: Text(
                                                rating > 0 ? 'Puanı Değiştir' : 'Puanla',
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: rating > 0
                                                    ? Colors.orange
                                                    : Colors.blue[700],
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 6,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        // Tekrarlama butonu
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: () => _repeatOrder(data),
                                            icon: const Icon(
                                              Icons.replay,
                                              size: 16,
                                            ),
                                            label: const Text('Bu Siparişi Tekrarla'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green[600],
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 8,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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
