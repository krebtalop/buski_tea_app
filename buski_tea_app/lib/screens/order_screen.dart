import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({Key? key}) : super(key: key);

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  String? _selectedProduct;
  int _quantity = 1;
  String _note = '';
  bool _isLoading = false;

  final List<String> _products = [
    'Çay',
    'Sütlü Çay',
    'Buzlu Çay',
    'Bitki Çayı',
  ];

  Future<void> _submitOrder() async {
    if (_selectedProduct == null) {
      setState(() {
        _isLoading = false;
      });
      print('Ürün seçilmedi!');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lütfen bir ürün seçin!')));
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        print('Kullanıcı oturumu yok!');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Kullanıcı oturumu yok!')));
        return;
      }
      print('Sipariş gönderiliyor...');
      final order = OrderModel(
        id: '',
        userId: user.uid,
        icecek: _selectedProduct!,
        adet: _quantity,
        not: _note,
        tarih: Timestamp.now(),
      );
      final doc = await FirebaseFirestore.instance
          .collection('siparisler')
          .add(order.toMap());
      await doc.update({'id': doc.id});
      setState(() {
        _isLoading = false;
      });
      print('Sipariş başarıyla gönderildi!');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Siparişiniz alındı!')));
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Sipariş gönderilemedi: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sipariş gönderilemedi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sipariş Ver')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ürün Seçin:'),
            DropdownButton<String>(
              value: _selectedProduct,
              hint: const Text('Ürün seçin'),
              items: _products.map((product) {
                return DropdownMenuItem(value: product, child: Text(product));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedProduct = value;
                });
              },
            ),
            const SizedBox(height: 16),
            const Text('Miktar:'),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: _quantity > 1
                      ? () {
                          setState(() {
                            _quantity--;
                          });
                        }
                      : null,
                ),
                Text(_quantity.toString()),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      _quantity++;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Not (isteğe bağlı):'),
            TextField(
              onChanged: (value) {
                setState(() {
                  _note = value;
                });
              },
              decoration: const InputDecoration(
                hintText: 'Eklemek istediğiniz notu yazın',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitOrder,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Siparişi Gönder'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
