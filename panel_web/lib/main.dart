import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCxtk5JjQiidKZtqOo0QvewUBK0W3TH2xk",
      authDomain: "buski-1b341.firebaseapp.com",
      projectId: "buski-1b341",
      storageBucket: "buski-1b341.firebasestorage.app",
      messagingSenderId: "463802150330",
      appId: "1:463802150330:web:02d0ada7954afb51658183",
      measurementId: "G-V072X4G0BM",
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Buski Çay Ocağı Sipariş Paneli',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Segoe UI',
      ),
      home: const OrderPanelScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class OrderPanelScreen extends StatefulWidget {
  const OrderPanelScreen({super.key});

  @override
  State<OrderPanelScreen> createState() => _OrderPanelScreenState();
}

class _OrderPanelScreenState extends State<OrderPanelScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<Map<String, dynamic>> allOrders = [];
  List<Map<String, dynamic>> menuData = [];
  String activeTab = 'preparing';
  List<String> lastOrderIds = [];

  // Default menu items
  final List<Map<String, dynamic>> defaultMenu = [
    {
      'name': 'Çay',
      'price': 2.0,
      'options': ['Şekersiz', 'Şekerli'],
      'defaultOption': 'Şekersiz',
    },
    {
      'name': 'Çay (Su Bardağı)',
      'price': 4.0,
      'options': ['Şekersiz', 'Şekerli'],
      'defaultOption': 'Şekersiz',
    },
    {
      'name': 'Bitki Çayı',
      'price': 2.0,
      'options': ['Çiçek', 'Adaçayı', 'Kuşburnu'],
      'defaultOption': 'Çiçek',
    },
    {
      'name': 'Oralet',
      'price': 2.0,
      'options': ['Şekersiz', 'Şekerli'],
      'defaultOption': 'Şekersiz',
    },
    {
      'name': 'Nescafe',
      'price': 8.0,
      'options': ['Sade', 'Sütlü'],
      'defaultOption': 'Sade',
    },
    {
      'name': 'Türk Kahvesi',
      'price': 10.0,
      'options': ['Sade', 'Orta', 'Şekerli'],
      'defaultOption': 'Sade',
    },
    {
      'name': 'Maden Suyu',
      'price': 10.0,
      'options': ['Sade', 'Elmalı', 'Limonlu', 'Narlı'],
      'defaultOption': 'Sade',
    },
    {'name': 'Sade Gazoz', 'price': 30.0, 'options': [], 'defaultOption': ''},
    {'name': 'Sarı Gazoz', 'price': 34.0, 'options': [], 'defaultOption': ''},
    {
      'name': "Çay Fişi 100'lü",
      'price': 200.0,
      'options': [],
      'defaultOption': '',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _listenToOrders();
    _listenToMenu();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    await _loadMenu();
    await _playNotificationSound();
  }

  Future<void> _loadMenu() async {
    try {
      final menuDoc = await _firestore.collection('menu').doc('main').get();
      if (menuDoc.exists) {
        setState(() {
          menuData = List<Map<String, dynamic>>.from(
            menuDoc.data()?['items'] ?? [],
          );
        });
      } else {
        // Create default menu
        await _firestore.collection('menu').doc('main').set({
          'items': defaultMenu,
        });
        setState(() {
          menuData = defaultMenu;
        });
      }
    } catch (e) {
      print('Error loading menu: $e');
    }
  }

  void _listenToMenu() {
    _firestore.collection('menu').doc('main').snapshots().listen((snapshot) {
      if (snapshot.exists) {
        setState(() {
          menuData = List<Map<String, dynamic>>.from(
            snapshot.data()?['items'] ?? [],
          );
        });
      }
    });
  }

  void _listenToOrders() {
    _firestore
        .collection('siparisler')
        .orderBy('tarih', descending: true)
        .snapshots()
        .listen((snapshot) {
          final currentOrderIds = snapshot.docs.map((doc) => doc.id).toList();

          // Check for new orders and play notification
          if (lastOrderIds.isNotEmpty &&
              currentOrderIds.length > lastOrderIds.length) {
            _playNotificationSound();
          }

          lastOrderIds = currentOrderIds;

          setState(() {
            allOrders = snapshot.docs.map((doc) {
              final data = doc.data();
              return {'id': doc.id, ...data};
            }).toList();
          });
        });
  }

  Future<void> _playNotificationSound() async {
    try {
      await _audioPlayer.play(
        UrlSource(
          'https://assets.mixkit.co/sfx/preview/mixkit-alarm-digital-clock-beep-989.mp3',
        ),
      );
    } catch (e) {
      print('Error playing notification sound: $e');
    }
  }

  void _setActiveTab(String tab) {
    setState(() {
      activeTab = tab;
    });
  }

  Future<void> _cycleOrderStatus(
    String orderId,
    Map<String, dynamic> order,
  ) async {
    try {
      final currentStatus = order['status'] ?? 'hazırlanıyor';
      String newStatus;

      if (currentStatus == 'hazırlanıyor') {
        newStatus = 'hazırlandı';
      } else if (currentStatus == 'hazırlandı') {
        newStatus = 'teslim edildi';
      } else {
        return;
      }

      await _firestore.collection('siparisler').doc(orderId).update({
        'status': newStatus,
      });
    } catch (e) {
      print('Error updating order status: $e');
    }
  }

  Future<void> _deleteOrder(String orderId) async {
    try {
      await _firestore.collection('siparisler').doc(orderId).delete();
    } catch (e) {
      print('Error deleting order: $e');
    }
  }

  List<Map<String, dynamic>> _getFilteredOrders(int floor) {
    return allOrders.where((order) {
      final orderFloor = int.tryParse(order['floor']?.toString() ?? '') ?? 0;
      final status = order['status'] ?? 'hazırlanıyor';

      if (activeTab == 'preparing') {
        return orderFloor == floor && status != 'teslim edildi';
      } else {
        return orderFloor == floor && status == 'teslim edildi';
      }
    }).toList();
  }

  int _getPreparingCount() {
    return allOrders.where((order) {
      final status = order['status'] ?? 'hazırlanıyor';
      return status != 'teslim edildi';
    }).length;
  }

  int _getDeliveredCount() {
    return allOrders.where((order) {
      final status = order['status'] ?? 'hazırlanıyor';
      return status == 'teslim edildi';
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_cafe, size: 32),
            const SizedBox(width: 12),
            const Text(
              'Çay Ocağı Sipariş Paneli',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Container(
            padding: const EdgeInsets.only(bottom: 8),
            child: const Text(
              'Siparişleri takip edin ve durumlarını güncelleyin',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    'preparing',
                    'Hazırlananlar',
                    _getPreparingCount(),
                  ),
                ),
                Expanded(
                  child: _buildTabButton(
                    'delivered',
                    'Teslim Edilenler',
                    _getDeliveredCount(),
                  ),
                ),
              ],
            ),
          ),

          // Floors Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Group 1: Floors 1-2-3
                  _buildFloorGroup('Katlar 1 - 2 - 3', [1, 2, 3]),
                  const SizedBox(height: 32),

                  // Group 2: Floors 4-5-6
                  _buildFloorGroup('Katlar 4 - 5 - 6', [4, 5, 6]),
                  const SizedBox(height: 32),

                  // Group 3: Floors 7-8-9-10
                  _buildFloorGroup('Katlar 7 - 8 - 9 - 10', [7, 8, 9, 10]),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMenuDialog(),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        child: const Icon(Icons.menu),
      ),
    );
  }

  Widget _buildTabButton(String tab, String title, int count) {
    final isActive = activeTab == tab;
    return Container(
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: isActive ? const Color(0xFF2563EB) : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      child: Stack(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _setActiveTab(tab),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isActive
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isActive
                          ? const Color(0xFF2563EB)
                          : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (count > 0)
            Positioned(
              top: 8,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: const BoxDecoration(
                  color: Color(0xFFDC2626),
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFloorGroup(String title, List<int> floors) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: floors.length,
            crossAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemCount: floors.length,
          itemBuilder: (context, index) {
            return _buildFloorCard(floors[index]);
          },
        ),
      ],
    );
  }

  Widget _buildFloorCard(int floor) {
    final orders = _getFilteredOrders(floor);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Kat $floor',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF374151),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: orders.isEmpty
                  ? _buildEmptyState()
                  : _buildOrdersList(orders),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            activeTab == 'preparing'
                ? 'Hazırlanacak sipariş yok'
                : 'Teslim edilen sipariş yok',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(List<Map<String, dynamic>> orders) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return _buildOrderCard(orders[index]);
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] ?? 'hazırlanıyor';
    final items = List<Map<String, dynamic>>.from(order['items'] ?? []);

    Color borderColor;
    Color backgroundColor;

    switch (status) {
      case 'hazırlanıyor':
        borderColor = const Color(0xFFF59E0B);
        backgroundColor = const Color(0xFFFEF3C7);
        break;
      case 'hazırlandı':
        borderColor = const Color(0xFF16A34A);
        backgroundColor = const Color(0xFFF0FDF4);
        break;
      case 'teslim edildi':
        borderColor = Colors.grey;
        backgroundColor = const Color(0xFFF1F5F9);
        break;
      default:
        borderColor = Colors.grey;
        backgroundColor = Colors.white;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: borderColor, width: 4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Info
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ad: ${order['ad'] ?? ''}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'Departman: ${order['departman'] ?? ''}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      if (order['tarih'] != null)
                        Text(
                          'Tarih: ${DateFormat('dd.MM.yyyy HH:mm').format((order['tarih'] as Timestamp).toDate())}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Order Items
            const Text(
              'Sipariş İçeriği:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  '${item['name']}${item['option'] != null ? ' (${item['option']})' : ''} - ${item['adet']} adet',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),

            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                'Toplam: ${order['toplamFiyat']?.toString() ?? '0'} ₺',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 8),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (activeTab == 'preparing')
                  _buildStatusButton(order)
                else
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Color(0xFF16A34A)),
                      SizedBox(width: 4),
                      Text(
                        'Teslim Edildi',
                        style: TextStyle(
                          color: Color(0xFF16A34A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                if (activeTab == 'delivered')
                  ElevatedButton.icon(
                    onPressed: () => _showDeleteConfirmation(order['id']),
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Sil'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton(Map<String, dynamic> order) {
    final status = order['status'] ?? 'hazırlanıyor';

    String buttonText;
    Color buttonColor;
    IconData icon;
    bool isDisabled = false;

    switch (status) {
      case 'hazırlanıyor':
        buttonText = 'Hazırlanıyor...';
        buttonColor = const Color(0xFFF59E0B);
        icon = Icons.hourglass_empty;
        break;
      case 'hazırlandı':
        buttonText = 'Hazırlandı';
        buttonColor = const Color(0xFF16A34A);
        icon = Icons.check;
        break;
      case 'teslim edildi':
        buttonText = 'Teslim Edildi';
        buttonColor = Colors.grey;
        icon = Icons.check_circle;
        isDisabled = true;
        break;
      default:
        buttonText = 'Hazırlanıyor...';
        buttonColor = const Color(0xFFF59E0B);
        icon = Icons.hourglass_empty;
    }

    return ElevatedButton.icon(
      onPressed: isDisabled
          ? null
          : () => _cycleOrderStatus(order['id'], order),
      icon: Icon(icon, size: 16),
      label: Text(buttonText),
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  void _showDeleteConfirmation(String orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Siparişi Sil'),
        content: const Text('Bu siparişi silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteOrder(orderId);
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _showMenuDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Menü'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: menuData.length,
            itemBuilder: (context, index) {
              final item = menuData[index];
              return ListTile(
                title: Text(item['name']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${item['price']} ₺'),
                    if (item['options'] != null &&
                        (item['options'] as List).isNotEmpty)
                      Text(
                        'Opsiyonlar: ${(item['options'] as List).join(', ')}',
                      ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditProductDialog(index),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showAddProductDialog();
            },
            child: const Text('Yeni Ürün Ekle'),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final optionsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Ürün Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Ürün Adı',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(
                labelText: 'Fiyat (₺)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: optionsController,
              decoration: const InputDecoration(
                labelText: 'Opsiyonlar (Virgülle ayırın)',
                border: OutlineInputBorder(),
                hintText: 'Örn: Sade, Şekerli, Limonlu',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final price = double.tryParse(priceController.text);
              final optionsText = optionsController.text.trim();

              if (name.isNotEmpty && price != null && price >= 0) {
                final options = optionsText.isNotEmpty
                    ? optionsText.split(',').map((e) => e.trim()).toList()
                    : [];

                final newProduct = {
                  'name': name,
                  'price': price,
                  'options': options,
                  'defaultOption': options.isNotEmpty ? options.first : '',
                };

                menuData.add(newProduct);
                await _firestore.collection('menu').doc('main').set({
                  'items': menuData,
                });

                Navigator.of(context).pop();
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  void _showEditProductDialog(int index) {
    final item = menuData[index];
    final nameController = TextEditingController(text: item['name']);
    final priceController = TextEditingController(
      text: item['price'].toString(),
    );
    final optionsController = TextEditingController(
      text: (item['options'] as List?)?.join(', ') ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ürünü Düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Ürün Adı',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(
                labelText: 'Fiyat (₺)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: optionsController,
              decoration: const InputDecoration(
                labelText: 'Opsiyonlar (Virgülle ayırın)',
                border: OutlineInputBorder(),
                hintText: 'Örn: Sade, Şekerli, Limonlu',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final price = double.tryParse(priceController.text);
              final optionsText = optionsController.text.trim();

              if (name.isNotEmpty && price != null && price >= 0) {
                final options = optionsText.isNotEmpty
                    ? optionsText.split(',').map((e) => e.trim()).toList()
                    : [];

                menuData[index] = {
                  'name': name,
                  'price': price,
                  'options': options,
                  'defaultOption': options.isNotEmpty ? options.first : '',
                };

                await _firestore.collection('menu').doc('main').set({
                  'items': menuData,
                });

                Navigator.of(context).pop();
              }
            },
            child: const Text('Güncelle'),
          ),
          TextButton(
            onPressed: () async {
              if (await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Ürünü Sil'),
                      content: const Text(
                        'Bu ürünü silmek istediğinizden emin misiniz?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('İptal'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFDC2626),
                          ),
                          child: const Text('Sil'),
                        ),
                      ],
                    ),
                  ) ==
                  true) {
                menuData.removeAt(index);
                await _firestore.collection('menu').doc('main').set({
                  'items': menuData,
                });
                Navigator.of(context).pop();
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}
