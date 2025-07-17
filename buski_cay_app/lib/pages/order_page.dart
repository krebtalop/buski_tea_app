import 'package:flutter/material.dart';

class MenuItem {
  final String name;
  final int price;
  final int ticketCount;
  final bool isTicket;
  MenuItem({required this.name, required this.price, required this.ticketCount, this.isTicket = false});
}

class OrderPage extends StatefulWidget {
  const OrderPage({Key? key}) : super(key: key);

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final List<MenuItem> menu = [
    MenuItem(name: 'Çay, Çiçek, Oralet vb.', price: 2, ticketCount: 1),
    MenuItem(name: 'Çay (Su Bardağı)', price: 4, ticketCount: 2),
    MenuItem(name: 'Nescafe', price: 8, ticketCount: 4),
    MenuItem(name: 'Türk Kahvesi', price: 10, ticketCount: 5),
    MenuItem(name: 'Sade Soda', price: 8, ticketCount: 4),
    MenuItem(name: 'Meyveli Soda', price: 10, ticketCount: 5),
    MenuItem(name: 'Narlı Soda', price: 12, ticketCount: 6),
    MenuItem(name: 'Sade Gazoz', price: 30, ticketCount: 15),
    MenuItem(name: 'Sarı Gazoz', price: 34, ticketCount: 17),
    MenuItem(name: 'Çay Fişi (100’lü)', price: 200, ticketCount: 0, isTicket: true),
  ];

  final Map<int, int> quantities = {};

  int get totalPrice {
    int total = 0;
    menu.asMap().forEach((i, item) {
      total += (quantities[i] ?? 0) * item.price;
    });
    return total;
  }

  int get totalTickets {
    int total = 0;
    menu.asMap().forEach((i, item) {
      if (!item.isTicket) {
        total += (quantities[i] ?? 0) * item.ticketCount;
      }
    });
    return total;
  }

  final Color cardColor = const Color(0xFFB3D9F3); // Tatlı bir mavi tonu
  final Color buttonColor = const Color(0xFFB497D6); // Açık tatlı mor

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sipariş Ver')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: menu.length,
              itemBuilder: (context, index) {
                final item = menu[index];
                final qty = quantities[index] ?? 0;
                return Card(
                  color: cardColor,
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(item.name),
                    subtitle: Text('${item.price} TL' + (item.isTicket ? '' : ' • ${item.ticketCount} fiş')), 
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: qty > 0 ? () {
                            setState(() {
                              quantities[index] = qty - 1;
                            });
                          } : null,
                        ),
                        Text(qty.toString()),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              quantities[index] = qty + 1;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Toplam Tutar: $totalPrice TL', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Toplam Fiş: $totalTickets', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: totalPrice > 0 ? () {} : null,
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
                      if (states.contains(MaterialState.disabled)) {
                        return null;
                      }
                      return buttonColor; // Açık tatlı mor
                    }),
                  ),
                  child: const Text(
                    'Siparişi Onayla',
                    style: TextStyle(color: Colors.white), // Beyaz yazı
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
