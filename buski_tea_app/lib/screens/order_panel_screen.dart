import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/order_controller.dart';
import '../models/order_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderPanelScreen extends StatelessWidget {
  final OrderController controller = Get.put(OrderController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Çay Ocağı Sipariş Paneli')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Grup butonları
            Obx(
              () => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...controller.groups.asMap().entries.map((entry) {
                      int idx = entry.key;
                      var group = entry.value;
                      return Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                controller.selectedGroupIdx.value == idx &&
                                    !controller.showTeslimEdildi.value
                                ? Colors.blue
                                : Colors.grey[300],
                            foregroundColor:
                                controller.selectedGroupIdx.value == idx &&
                                    !controller.showTeslimEdildi.value
                                ? Colors.white
                                : Colors.black,
                          ),
                          onPressed: () => controller.selectGroup(idx),
                          child: Text(group['name'].toString()),
                        ),
                      );
                    }),
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: controller.showTeslimEdildi.value
                              ? Colors.green
                              : Colors.grey[300],
                          foregroundColor: controller.showTeslimEdildi.value
                              ? Colors.white
                              : Colors.black,
                        ),
                        onPressed: controller.showTeslimEdildiView,
                        child: const Text('TESLİM EDİLDİ'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Sipariş sütunları
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                final group =
                    controller.groups[controller.selectedGroupIdx.value];
                final floors = group['floors'] as List<int>;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: floors.map((floor) {
                    final orders = controller.orders.where((order) {
                      final status = order.toMap()['status'] ?? 'hazırlanıyor';
                      final floorValue = order.toMap()['floor'];
                      int? floorInt;
                      if (floorValue is int) {
                        floorInt = floorValue;
                      } else if (floorValue is String) {
                        floorInt = int.tryParse(floorValue);
                      }
                      return floorInt == floor &&
                          (controller.showTeslimEdildi.value
                              ? status == 'teslim edildi'
                              : status != 'teslim edildi');
                    }).toList();
                    return Expanded(
                      child: Card(
                        margin: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Text(
                              'Kat $floor',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ...orders.map((order) {
                              final data = order.toMap();
                              final status = data['status'] ?? 'hazırlanıyor';
                              return Card(
                                margin: const EdgeInsets.all(8),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Ad: ${data['ad'] ?? ''}'),
                                      Text(
                                        'Departman: ${data['departman'] ?? ''}',
                                      ),
                                      Text('Telefon: ${data['telefon'] ?? ''}'),
                                      Text(
                                        'Tarih: '
                                        '${data['tarih'] is Timestamp ? (data['tarih'] as Timestamp).toDate().toString() : (data['tarih']?.toString() ?? '')}',
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Sipariş İçeriği:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      ...((data['items'] as List?) ?? []).map((
                                        item,
                                      ) {
                                        return Text(
                                          '${item['name']} ${item['option'] != null ? '(' + item['option'] + ')' : ''} - ${item['adet']} adet',
                                        );
                                      }).toList(),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Toplam Tutar: ${data['toplamFiyat'] ?? ''} ₺',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Divider(),
                                      Row(
                                        children: [
                                          ElevatedButton(
                                            onPressed: status == 'teslim edildi'
                                                ? null
                                                : () => controller
                                                      .updateOrderStatus(
                                                        order.id,
                                                        status,
                                                      ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  status == 'hazırlandı'
                                                  ? Colors.green
                                                  : status == 'teslim edildi'
                                                  ? Colors.grey
                                                  : Colors.yellow[700],
                                              foregroundColor: Colors.white,
                                            ),
                                            child: Text(
                                              status == 'hazırlandı'
                                                  ? 'Hazırlandı'
                                                  : status == 'teslim edildi'
                                                  ? 'Teslim Edildi'
                                                  : 'Hazırlanıyor...',
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                            ),
                                            onPressed: () => controller
                                                .deleteOrder(order.id),
                                            child: const Text('Sil'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                            if (orders.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  'Sipariş yok',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
