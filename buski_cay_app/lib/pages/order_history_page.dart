import 'package:flutter/material.dart';

class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Örnek sipariş verisi
    final List<Map<String, dynamic>> orders = [
      {
        'date': '2024-06-01',
        'items': [
          {'name': 'Çay', 'qty': 2},
          {'name': 'Nescafe', 'qty': 1},
        ],
        'total': 12,
      },
      {
        'date': '2024-05-28',
        'items': [
          {'name': 'Sade Gazoz', 'qty': 1},
        ],
        'total': 30,
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Geçmiş Siparişlerim')),
      body: ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              title: Text('Tarih: ${order['date']}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...List.generate(order['items'].length, (i) {
                    final item = order['items'][i];
                    return Text('${item['name']} x${item['qty']}');
                  }),
                  const SizedBox(height: 4),
                  Text('Toplam: ${order['total']} TL'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
} 