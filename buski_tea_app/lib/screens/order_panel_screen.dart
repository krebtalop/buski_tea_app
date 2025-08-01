import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/order_controller.dart';
import '../models/order_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderPanelScreen extends StatelessWidget {
  final OrderController controller = Get.put(OrderController());

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Çay Ocağı Sipariş Paneli'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Siparişler'),
              Tab(text: 'Yorumlar'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Siparişler Sekmesi
            Padding(
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
      // Yorumlar Sekmesi
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Kat grupları için butonlar
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
                            backgroundColor: controller.selectedGroupIdx.value == idx
                                ? Colors.blue
                                : Colors.grey[300],
                            foregroundColor: controller.selectedGroupIdx.value == idx
                                ? Colors.white
                                : Colors.black,
                          ),
                          onPressed: () => controller.selectGroup(idx),
                          child: Text('${group['name']} Yorumları'),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Yorumlar sütunları
            Expanded(
              child: Obx(() {
                if (controller.isLoadingRatings.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                final group = controller.groups[controller.selectedGroupIdx.value];
                final floors = group['floors'] as List<int>;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: floors.map((floor) {
                    final floorRatings = controller.getRatingsByFloor(floor);
                    return Expanded(
                      child: Card(
                        margin: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Text(
                              'Kat $floor Yorumları',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ...floorRatings.map((rating) {
                              return Card(
                                margin: const EdgeInsets.all(8),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${rating.userName}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Row(
                                            children: List.generate(5, (index) {
                                              return Icon(
                                                Icons.star,
                                                size: 16,
                                                color: index < rating.rating
                                                    ? Colors.amber
                                                    : Colors.grey,
                                              );
                                            }),
                                          ),
                                        ],
                                      ),
                                      Text('Departman: ${rating.userDepartment}'),
                                      Text(
                                        'Tarih: ${rating.timestamp.toString().substring(0, 19)}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          rating.comment.isNotEmpty
                                              ? rating.comment
                                              : 'Yorum yok',
                                          style: const TextStyle(fontStyle: FontStyle.italic),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                            ),
                                            onPressed: () => controller.deleteRating(rating.id),
                                            child: const Text('Sil'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                            if (floorRatings.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  'Bu kattan henüz yorum yok',
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
    ],
  ),
),
);
}
}
