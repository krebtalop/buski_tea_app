import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String userId;
  final String icecek;
  final int adet;
  final String not;
  final Timestamp tarih;

  OrderModel({
    required this.id,
    required this.userId,
    required this.icecek,
    required this.adet,
    required this.not,
    required this.tarih,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'icecek': icecek,
      'adet': adet,
      'not': not,
      'tarih': tarih,
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      icecek: map['icecek'] ?? '',
      adet: map['adet'] ?? 0,
      not: map['not'] ?? '',
      tarih: map['tarih'] ?? Timestamp.now(),
    );
  }
}
