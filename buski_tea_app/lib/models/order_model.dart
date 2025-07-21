import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String userId;
  final Timestamp tarih;
  final double toplamFiyat;
  final List<Map<String, dynamic>> items;

  OrderModel({
    required this.id,
    required this.userId,
    required this.tarih,
    required this.toplamFiyat,
    required this.items,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'tarih': tarih,
      'toplamFiyat': toplamFiyat,
      'items': items,
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      tarih: map['tarih'] ?? Timestamp.now(),
      toplamFiyat: (map['toplamFiyat'] ?? 0.0).toDouble(),
      items: List<Map<String, dynamic>>.from(map['items'] ?? []),
    );
  }
}
