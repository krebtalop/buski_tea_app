import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_screen.dart';
import 'dart:async';

class OrderScreen extends StatefulWidget {
  const OrderScreen({Key? key}) : super(key: key);

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  final List<Map<String, dynamic>> _cartItems = [];
  bool _cartDropdownOpen = false;

  List<Map<String, dynamic>> _menu = [];
  bool _isMenuLoading = true;
  late final StreamSubscription _menuSubscription;

  final Map<String, int> _quantities = {};
  final Map<String, String> _selectedOptions = {};
  bool _isLoading = false;
  bool _showTopNotification = false;
  String _notificationMessage = '';

  // Animasyon için
  List<bool> _cardVisible = [];
  // Bulut animasyonu ile ilgili tüm değişkenler ve controllerlar kaldırıldı

  @override
  void initState() {
    super.initState();
    _listenMenuRealtime();
    for (var item in _menu) {
      _quantities[item['name']] = 1;
      _selectedOptions[item['name']] = item['defaultOption'] ?? '';
    }
    _cardVisible = List.generate(_menu.length, (index) => false);
    if (_menu.isNotEmpty) {
      // Kartları animasyonlu şekilde aç
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCardsAnimated();
      });
    }
    // Bulut animasyonu başlatma kodları kaldırıldı
  }

  void _listenMenuRealtime() async {
    // Kullanıcının kat bilgisini al
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isMenuLoading = false;
        _menu = [];
      });
      return;
    }

    // Kullanıcı profil bilgilerini al
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final userData = userDoc.data() ?? {};
    final floor = userData['floor']?.toString() ?? '0'; // int'i string'e çevir

    print('Kullanıcı kat bilgisi: $floor'); // Debug için

    // Kat bilgisine göre menü koleksiyonunu belirle
    String menuCollection;
    int floorNumber = int.tryParse(floor) ?? 0;

    if (floorNumber >= 0 && floorNumber <= 3) {
      menuCollection = 'kat123';
    } else if (floorNumber >= 4 && floorNumber <= 6) {
      menuCollection = 'kat456';
    } else if (floorNumber >= 7 && floorNumber <= 10) {
      menuCollection = 'kat78910';
    } else {
      menuCollection = 'kat123'; // Varsayılan
    }

    print('Seçilen menü koleksiyonu: $menuCollection'); // Debug için

    final menuDocRef = FirebaseFirestore.instance
        .collection('menu')
        .doc(menuCollection);

    setState(() {
      _isMenuLoading = true;
    });

    _menuSubscription = menuDocRef.snapshots().listen((docSnap) {
      if (docSnap.exists &&
          docSnap.data() != null &&
          docSnap.data()!['items'] is List) {
        setState(() {
          _menu = List<Map<String, dynamic>>.from(
            (docSnap.data()!['items'] as List).map(
              (e) => Map<String, dynamic>.from(e),
            ),
          );
          _isMenuLoading = false;
          _quantities.clear();
          _selectedOptions.clear();
          for (var item in _menu) {
            _quantities[item['name']] = 1;
            _selectedOptions[item['name']] = item['defaultOption'] ?? '';
          }
          _cardVisible = List.generate(_menu.length, (index) => false);
          if (_menu.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showCardsAnimated();
            });
          }
        });
      } else {
        setState(() {
          _menu = [];
          _isMenuLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _menuSubscription.cancel();
    super.dispose();
  }

  void _showCardsAnimated() async {
    for (int i = 0; i < _menu.length; i++) {
      await Future.delayed(const Duration(milliseconds: 80));
      if (mounted) {
        setState(() {
          _cardVisible[i] = true;
        });
      }
    }
  }

  void _addToCart(String productName, int adet, String option, int price) {
    setState(() {
      // Aynı ürün ve aynı seçenekle sepette var mı kontrol et
      int existingIndex = _cartItems.indexWhere(
        (item) => item['name'] == productName && item['option'] == option,
      );

      if (existingIndex != -1) {
        // Varsa adetini arttır
        _cartItems[existingIndex]['adet'] += adet;
      } else {
        // Yoksa yeni item ekle
        _cartItems.add({
          'name': productName,
          'adet': adet,
          'option': option,
          'price': price,
        });
      }

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

    double totalPrice = _cartItems.fold(
      0,
      (sum, item) => sum + (item['price'] * item['adet']),
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Kullanıcı oturumu yok!')));
        return;
      }
      // Kullanıcı profil bilgilerini Firestore'dan çek
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = userDoc.data() ?? {};
      final ad = userData['name'] ?? '';
      final soyad = userData['surname'] ?? '';
      final departman = userData['department'] ?? '';
      final floor = userData['floor'] ?? '';
      final orderRef = FirebaseFirestore.instance
          .collection('siparisler')
          .doc();
      final userOrderRef = FirebaseFirestore.instance
          .collection('user_orders')
          .doc(user.uid)
          .collection('orders')
          .doc(orderRef.id);
      final newOrder = {
        // Kullanıcı bilgileri
        'userId': user.uid,
        'email': user.email,
        'ad': ad,
        'soyad': soyad,
        'departman': departman,
        'floor': floor,
        // Sipariş bilgileri
        'id': orderRef.id,
        'tarih': Timestamp.now(),
        'toplamFiyat': totalPrice,
        'items': _cartItems,
      };
      await Future.wait([orderRef.set(newOrder), userOrderRef.set(newOrder)]);
      setState(() {
        _cartItems.clear();
        _notificationMessage = 'Tüm siparişleriniz başarıyla alındı!';
        _showTopNotification = true;
      });

      // 3 saniye sonra bildirimi kapat
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _showTopNotification = false);
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Siparişler gönderilemedi: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _toggleCartDropdown() =>
      setState(() => _cartDropdownOpen = !_cartDropdownOpen);

  Widget _buildOrderMenu() {
    if (_isMenuLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        Expanded(
          child: Container(
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
            child: _menu.isEmpty
                ? const Center(
                    child: Text(
                      'Menü bulunamadı',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _menu.length,
                    itemBuilder: (context, index) {
                      final item = _menu[index];
                      final name = item['name'] as String;
                      // price güvenli şekilde alınacak:
                      final price = (item['price'] is int)
                          ? item['price'] as int
                          : (item['price'] is double)
                          ? (item['price'] as double).toInt()
                          : int.tryParse(item['price'].toString()) ?? 0;
                      final options = List<String>.from(item['options']);
                      final hasOptions = options.isNotEmpty;

                      final inStock =
                          item['inStock'] != false; // Varsayılan true

                      // _cardVisible güvenli erişim
                      final visible = index < _cardVisible.length
                          ? _cardVisible[index]
                          : true;

                      return AnimatedOpacity(
                        opacity: visible ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOut,
                        child: AnimatedSlide(
                          offset: visible ? Offset.zero : const Offset(0, 0.15),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOut,
                          child: Card(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                              side: BorderSide(
                                color: Colors.blue[100]!,
                                width: 1.0,
                              ),
                            ),
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 1,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          name,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[50],
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          '$price TL',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            color: Color(0xFF1976D2),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Text(
                                        'Adet:',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove,
                                          color: Colors.black,
                                          size: 18,
                                        ),
                                        onPressed: _quantities[name]! > 1
                                            ? () => setState(
                                                () => _quantities[name] =
                                                    _quantities[name]! - 1,
                                              )
                                            : null,
                                      ),
                                      Text(
                                        _quantities[name].toString(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.black,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.add,
                                          color: Colors.black,
                                          size: 18,
                                        ),
                                        onPressed: () => setState(
                                          () => _quantities[name] =
                                              _quantities[name]! + 1,
                                        ),
                                      ),
                                      if (hasOptions)
                                        DropdownButton<String>(
                                          value: _selectedOptions[name],
                                          dropdownColor: Colors.white,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                          items: options
                                              .map(
                                                (opt) => DropdownMenuItem(
                                                  value: opt,
                                                  child: Text(opt),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (val) => setState(
                                            () => _selectedOptions[name] = val!,
                                          ),
                                          underline: const SizedBox(),
                                          iconSize: 22,
                                        ),
                                      const Spacer(),
                                      ElevatedButton(
                                        onPressed: inStock
                                            ? () => _addToCart(
                                                name,
                                                _quantities[name] ?? 1,
                                                hasOptions
                                                    ? _selectedOptions[name] ??
                                                          ''
                                                    : '',
                                                price,
                                              )
                                            : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: inStock
                                              ? Colors.blue
                                              : Colors.grey,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 18,
                                            vertical: 10,
                                          ),
                                          textStyle: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: Text('Sepete Ekle'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
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
    double totalPrice = _cartItems.fold(
      0,
      (sum, item) => sum + (item['price'] * item['adet']),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _toggleCartDropdown,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blue[900]?.withOpacity(0.9),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
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
                        foregroundColor: Colors.blue[800],
                      ),
                      onPressed: _isLoading ? null : _submitAllOrders,
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(),
                            )
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
          crossFadeState: _cartDropdownOpen
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
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
                  Expanded(
                    child: Text(
                      '${entry.value['name']} x${entry.value['adet']} ${entry.value['option'] != '' ? '(${entry.value['option']})' : ''}',
                    ),
                  ),
                  Text(
                    '${(entry.value['price'] * entry.value['adet']).toStringAsFixed(2)} TL',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => _removeFromCart(entry.key),
                  ),
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
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          decoration: BoxDecoration(
            color: _notificationMessage.contains('başarıyla')
                ? Colors.green
                : Colors.black.withOpacity(0.8),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_notificationMessage.contains('başarıyla'))
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
              if (_notificationMessage.contains('başarıyla'))
                const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _notificationMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
                  ),
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Stack(
          children: [
            // Degrade arka plan
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
                boxShadow: [
                  BoxShadow(
                    color: Color(0x331976D2),
                    blurRadius: 18,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
            ),
            // Animasyonlu bulutlar başlıkla aynı hizada
            // if (_cloudAnims != null && _cloudPositions != null)
            //   Stack(
            //     children: List.generate(_cloudAnims!.length, (i) {
            //       final anim = _cloudAnims![i];
            //       final width = MediaQuery.of(context).size.width;
            //       final double left = _cloudPositions![i] * width;
            //       if (left + anim.size < 0 || left > width) {
            //         return const SizedBox.shrink();
            //       }
            //       return Positioned(
            //         top: anim.top,
            //         left: left,
            //         child: Opacity(
            //           opacity: anim.opacity,
            //           child: Image.asset(
            //             'assets/images/cloud.png',
            //             width: anim.size,
            //             height: anim.size * 0.6,
            //           ),
            //         ),
            //       );
            //     }),
            //   ),
            // Başlık
            SafeArea(
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: Text(
                    _selectedIndex == 0 ? 'Buski Çay Ocağı Menüsü' : 'Profil',
                    key: ValueKey(_selectedIndex),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          _selectedIndex == 0 ? _buildOrderMenu() : const ProfileScreen(),
          _buildTopNotification(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavBarItem(
                icon: Icons.shopping_cart,
                label: 'Sipariş',
                selected: _selectedIndex == 0,
                onTap: () {
                  if (_selectedIndex != 0) {
                    setState(() {
                      _selectedIndex = 0;
                      _cardVisible = List.generate(
                        _menu.length,
                        (index) => false,
                      );
                    });
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _showCardsAnimated();
                    });
                  }
                },
              ),
              _NavBarItem(
                icon: Icons.person,
                label: 'Profil',
                selected: _selectedIndex == 1,
                onTap: () => setState(() => _selectedIndex = 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Modern alt navigasyon bar item widget'ı
class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? Colors.blue[50] : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: selected ? Colors.blue[800] : Colors.grey[400],
                size: selected ? 28 : 24,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.blue[800] : Colors.grey[500],
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  fontSize: selected ? 15 : 13,
                ),
              ),
              if (selected)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  height: 3,
                  width: 24,
                  decoration: BoxDecoration(
                    color: Colors.blue[800],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Bulut animasyonu modeli
// _CloudAnim sınıfı ve ilgili model tamamen kaldırıldı