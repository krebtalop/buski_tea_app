import 'package:cloud_firestore/cloud_firestore.dart';

class RatingModel {
  final String id;
  final String orderId;
  final String userId;
  final String userEmail;
  final String userName;
  final int userFloor;
  final String userDepartment;
  final int rating;
  final String comment;
  final DateTime timestamp;

  RatingModel({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.userFloor,
    required this.userDepartment,
    required this.rating,
    required this.comment,
    required this.timestamp,
  });

  factory RatingModel.fromMap(Map<String, dynamic> map, String id) {
    return RatingModel(
      id: id,
      orderId: map['orderId'] ?? '',
      userId: map['userId'] ?? '',
      userEmail: map['userEmail'] ?? '',
      userName: map['userName'] ?? '',
      userFloor: map['userFloor'] ?? 0,
      userDepartment: map['userDepartment'] ?? '',
      rating: map['rating'] ?? 0,
      comment: map['comment'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'userFloor': userFloor,
      'userDepartment': userDepartment,
      'rating': rating,
      'comment': comment,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
} 