import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class WebOrderScreen extends StatefulWidget {
  const WebOrderScreen({Key? key}) : super(key: key);

  @override
  State<WebOrderScreen> createState() => _WebOrderScreenState();
}

class _WebOrderScreenState extends State<WebOrderScreen> {
  final List<Map<String, dynamic>> _cartItems = [];
  final Map<String, int> _quantities = {};
  final Map<String, String> _selectedOptions = {};
  bool _isLoading = false;
  bool _showNotification = false;
  String _notificationMessage = '';
  
  // Web için basit menü
  final List<Map<String, dynamic>> _menu = [
    {
      'name': 'Çay',
      'price': 5.0,
      'options': ['Şekerli', 'Şekersiz', 'Az Şekerli'],
      'defaultOption': 'Şekerli',
      'image': '🍵',
    },
    {
      'name': 'Kahve',
      'price': 8.0,
      'options': ['Sade', 'Sütlü', 'Şekerli'],
      'defaultOption': 'Sade',
      'image': '☕',
    },
    {
      'name': 'Su',
      'price': 2.0,
      'options': ['Soğuk', 'Ilık'],
      'defaultOption': 'Soğuk',
      'image': '💧',
    },
    {
      'name': 'Meyve Suyu',
      'price': 6.0,
      'options': ['Portakal', 'Elma', 'Vişne'],
      'defaultOption': 'Portakal',
      'image': '🍊',
    },
  ];

  @override
  void initState() {
    super.initState();
    for (var item in _menu) {
      _quantities[item['name']] = 0;
      _selectedOptions[item['name']] = item['defaultOption'];
    }
  }

  void _addToCart(String itemName) {
    setState(() {
      if (_quantities[itemName]! > 0) {
        // Sepette zaten varsa güncelle
        bool found = false;
        for (int i = 0; i < _cartItems.length; i++) {
          if (_cartItems[i]['name'] == itemName && 
              _cartItems[i]['option'] == _selectedOptions[itemName]) {
            _cartItems[i]['quantity'] += _quantities[itemName]!;
            found = true;
            break;
          }
        }
        
        if (!found) {
          // Sepete yeni ekle
          _cartItems.add({
            'name': itemName,
            'quantity': _quantities[itemName]!,
            'price': _menu.firstWhere((item) => item['name'] == itemName)['price'],
            'option': _selectedOptions[itemName],
          });
        }
        
        _quantities[itemName] = 0;
        _showNotificationMessage('Sepete eklendi!');
      }
    });
  }

  void _removeFromCart(int index) {
    setState(() {
      _cartItems.removeAt(index);
    });
  }

  void _showNotificationMessage(String message) {
    setState(() {
      _notificationMessage = message;
      _showNotification = true;
    });
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showNotification = false;
        });
      }
    });
  }

  Future<void> _submitOrder() async {
    if (_cartItems.isEmpty) {
      _showNotificationMessage('Sepetiniz boş!');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Rastgele sipariş numarası oluştur
      final orderNumber = Random().nextInt(9000) + 1000;
      
      // Siparişi Firebase'e gönder
      await FirebaseFirestore.instance.collection('siparisler').add({
        'orderNumber': orderNumber,
        'items': _cartItems,
        'totalAmount': _cartItems.fold(0.0, (sum, item) => sum + (item['price'] * item['quantity'])),
        'status': 'beklemede',
        'timestamp': Timestamp.now(),
        'source': 'web',
        'customerInfo': {
          'name': 'Web Müşteri',
          'floor': 'Web',
          'room': 'Web',
        },
      });

      setState(() {
        _cartItems.clear();
        _isLoading = false;
      });

      _showNotificationMessage('Siparişiniz başarıyla gönderildi! Sipariş No: $orderNumber');
      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showNotificationMessage('Sipariş gönderilirken hata oluştu: $e');
    }
  }

  double get _totalAmount {
    return _cartItems.fold(0.0, (sum, item) => sum + (item['price'] * item['quantity']));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Buski Çay Ocağı - Web Sipariş'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Row(
            children: [
              // Sol taraf - Menü
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Menü',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.2,
                          ),
                          itemCount: _menu.length,
                          itemBuilder: (context, index) {
                            final item = _menu[index];
                            return _buildMenuItem(item);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Sağ taraf - Sepet
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sepetiniz',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: _cartItems.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.shopping_cart_outlined,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Sepetiniz boş',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: _cartItems.length,
                                itemBuilder: (context, index) {
                                  final item = _cartItems[index];
                                  return _buildCartItem(item, index);
                                },
                              ),
                      ),
                      if (_cartItems.isNotEmpty) ...[
                        const Divider(),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Toplam:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            Text(
                              '₺${_totalAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitOrder,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[800],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Siparişi Gönder',
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Bildirim
          if (_showNotification)
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.green[600],
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Text(
                  _notificationMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(Map<String, dynamic> item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  item['image'],
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₺${item['price'].toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Seçenek dropdown
            DropdownButtonFormField<String>(
              value: _selectedOptions[item['name']],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
              items: (item['options'] as List<String>).map((option) {
                return DropdownMenuItem(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedOptions[item['name']] = value!;
                });
              },
            ),
            
            const SizedBox(height: 12),
            
            // Miktar seçici
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      if (_quantities[item['name']]! > 0) {
                        _quantities[item['name']] = _quantities[item['name']]! - 1;
                      }
                    });
                  },
                  icon: const Icon(Icons.remove_circle_outline),
                  color: Colors.red[400],
                ),
                Expanded(
                  child: Text(
                    '${_quantities[item['name']]}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _quantities[item['name']] = _quantities[item['name']]! + 1;
                    });
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  color: Colors.green[600],
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Sepete ekle butonu
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _quantities[item['name']]! > 0 ? () => _addToCart(item['name']) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Sepete Ekle'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${item['option']} - ${item['quantity']} adet',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                Text(
                  '₺${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _removeFromCart(index),
            icon: const Icon(Icons.delete_outline),
            color: Colors.red[400],
            iconSize: 20,
          ),
        ],
      ),
    );
  }
} 