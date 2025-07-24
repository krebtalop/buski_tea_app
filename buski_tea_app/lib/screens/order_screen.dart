import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import 'profile_screen.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({Key? key}) : super(key: key);

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  int _selectedIndex = 0;
  final List<Map<String, dynamic>> _cartItems = [];
  bool _cartDropdownOpen = false;

  final List<Map<String, dynamic>> _menu = [
    {'name': 'Çay', 'price': 2, 'options': ['Şekersiz', 'Şekerli'], 'defaultOption': 'Şekersiz'},
    {'name': 'Çay (Su Bardağı)', 'price': 4, 'options': ['Şekersiz','Şekerli'], 'defaultOption': 'Şekersiz'},
    {'name': 'Bitki Çayı', 'price': 2, 'options': ['Çiçek', 'Adaçayı', 'Kuşburnu'], 'defaultOption': 'Çiçek'},
    {'name': 'Oralet', 'price': 2, 'options': ['Şekersiz', 'Şekerli'], 'defaultOption': 'Şekersiz'},
    {'name': 'Nescafe', 'price': 8, 'options': ['Sade', 'Sütlü'], 'defaultOption': 'Sade'},
    {'name': 'Türk Kahvesi', 'price': 10, 'options': ['Sade', 'Orta', 'Şekerli'], 'defaultOption': 'Sade'},
    {'name': 'Maden Suyu', 'price': 10, 'options': ['Sade', 'Elmalı', 'Limonlu', 'Narlı'], 'defaultOption': 'Sade'},
    {'name': 'Sade Gazoz', 'price': 30, 'options': [], 'defaultOption': ''},
    {'name': 'Sarı Gazoz', 'price': 34, 'options': [], 'defaultOption': ''},
    {'name': "Çay Fişi 100'lü", 'price': 200, 'options': [], 'defaultOption': ''},
  ];

  final Map<String, int> _quantities = {};
  final Map<String, String> _selectedOptions = {};
  bool _isLoading = false;
  bool _showTopNotification = false;
  String _notificationMessage = '';

  @override
  void initState() {
    super.initState();
    for (var item in _menu) {
      _quantities[item['name']] = 1;
      _selectedOptions[item['name']] = item['defaultOption'] ?? '';
    }
  }

  void _addToCart(String productName, int adet, String option, int price) {
    setState(() {
      _cartItems.add({'name': productName, 'adet': adet, 'option': option, 'price': price});
      _notificationMessage = '$productName sepete eklendi.';
      _showTopNotification = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showTopNotification = false);
      }
    });
  }

  void _removeFromCart(int index) => setState(() => _cartItems.removeAt(index));

  Future<void> _submitAllOrders() async {
    if (_cartItems.isEmpty) return;
    setState(() => _isLoading = true);

    double totalPrice = _cartItems.fold(0, (sum, item) => sum + (item['price'] * item['adet']));

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kullanıcı oturumu yok!')));
        return;
      }
      // Kullanıcı profil bilgilerini Firestore'dan çek
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};
      final ad = userData['name'] ?? '';
      final soyad = userData['surname'] ?? '';
      final departman = userData['department'] ?? '';
      final floor = userData['floor'] ?? '';
      final orderRef = FirebaseFirestore.instance.collection('siparisler').doc();
      final newOrder = {
        'id': orderRef.id,
        'userId': user.uid,
        'email': user.email,
        'ad': ad,
        'soyad': soyad,
        'departman': departman,
        'floor': floor,
        'tarih': Timestamp.now(),
        'toplamFiyat': totalPrice,
        'items': _cartItems,
      };
      await orderRef.set(newOrder);
      setState(() => _cartItems.clear());
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tüm siparişleriniz başarıyla alındı!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Siparişler gönderilemedi: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _toggleCartDropdown() => setState(() => _cartDropdownOpen = !_cartDropdownOpen);

  Widget _buildOrderMenu() {
    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1565C0), Color(0xFF42A5F5), Color(0xFFB3E5FC)],
              ),
            ),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _menu.length,
              itemBuilder: (context, index) {
                final item = _menu[index];
                final name = item['name'] as String;
                final price = item['price'] as int;
                final options = List<String>.from(item['options']);
                final hasOptions = options.isNotEmpty;

                return Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                    side: BorderSide(color: Colors.blue[100]!, width: 1.0),
                  ),
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$price TL',
                                style: const TextStyle(fontSize: 18, color: Color(0xFF1976D2), fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text('Adet:', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500, fontSize: 13)),
                            IconButton(
                              icon: const Icon(Icons.remove, color: Colors.black, size: 18),
                              onPressed: _quantities[name]! > 1 ? () => setState(() => _quantities[name] = _quantities[name]! - 1) : null,
                            ),
                            Text(
                              _quantities[name].toString(),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, color: Colors.black, size: 18),
                              onPressed: () => setState(() => _quantities[name] = _quantities[name]! + 1),
                            ),
                            if (hasOptions)
                              DropdownButton<String>(
                                value: _selectedOptions[name],
                                dropdownColor: Colors.white,
                                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 14),
                                items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
                                onChanged: (val) => setState(() => _selectedOptions[name] = val!),
                                underline: const SizedBox(),
                                iconSize: 22,
                              ),
                            const Spacer(),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1976D2),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              onPressed: _isLoading
                                  ? null
                                  : () => _addToCart(name, _quantities[name]!, hasOptions ? _selectedOptions[name]! : '', price),
                              child: _isLoading
                                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Sepete Ekle'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (_cartItems.isNotEmpty) _buildCartSummary(),
      ],
    );
  }

Widget _buildCartSummary() {
  double totalPrice = _cartItems.fold(0, (sum, item) => sum + (item['price'] * item['adet']));
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      GestureDetector(
        onTap: _toggleCartDropdown,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.blue[900]?.withOpacity(0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Toplam: ${totalPrice.toStringAsFixed(2)} TL',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Icon(
                    _cartDropdownOpen
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue[800]),
                    onPressed: _isLoading ? null : _submitAllOrders,
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator())
                        : const Text('Tüm Siparişleri Ver'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      AnimatedCrossFade(
        firstChild: const SizedBox.shrink(),
        secondChild: _buildCartDropdown(),
        crossFadeState:
            _cartDropdownOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        duration: const Duration(milliseconds: 300),
      ),
    ],
  );
}



  Widget _buildCartDropdown() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _cartItems
            .asMap()
            .entries
            .map(
              (entry) => Row(
                children: [
                  Expanded(child: Text('${entry.value['name']} x${entry.value['adet']} ${entry.value['option'] != '' ? '(${entry.value['option']})' : ''}')),
                  Text('${(entry.value['price'] * entry.value['adet']).toStringAsFixed(2)} TL'),
                  IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => _removeFromCart(entry.key)),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildTopNotification() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      top: _showTopNotification ? 0 : -100,
      left: 0,
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.only(top: 7, bottom: 0, left: 24, right: 24),
          color: Colors.black.withOpacity(0.1),
          child: Text(
            _notificationMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16.0),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'Buski Çay Ocağı Menüsü' : 'Profil'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          _selectedIndex == 0 ? _buildOrderMenu() : const ProfileScreen(),
          _buildTopNotification(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.blue[800],
        unselectedItemColor: Colors.blue[200],
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Sipariş'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}