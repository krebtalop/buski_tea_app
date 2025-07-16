import 'package:flutter/material.dart';

class TeaOrdersScreen extends StatelessWidget {
  final int kat;
  const TeaOrdersScreen({Key? key, required this.kat}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Çay Ocağı Siparişleri - $kat. Kat')),
      body: ListView.builder(
        itemCount: 5, // Örnek veri
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              title: Text('Sipariş #${index + 1}'),
              subtitle: Text('Sipariş detayı burada'),
              trailing: ElevatedButton(
                onPressed: () {},
                child: const Text('Tamamlandı'),
              ),
            ),
          );
        },
      ),
    );
  }
} 