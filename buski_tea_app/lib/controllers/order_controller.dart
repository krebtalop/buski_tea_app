import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../models/rating_model.dart';

class OrderController extends GetxController {
  // Kat grupları
  final groups = [
    {
      'name': 'Kat 1-2-3',
      'floors': [1, 2, 3],
    },
    {
      'name': 'Kat 4-5-6',
      'floors': [4, 5, 6],
    },
    {
      'name': 'Kat 7-8-9-10',
      'floors': [7, 8, 9, 10],
    },
  ];
  var selectedGroupIdx = 0.obs;
  var showTeslimEdildi = false.obs;

  // Siparişler
  var orders = <OrderModel>[].obs;
  late final Stream<QuerySnapshot> _orderStream;
  var isLoading = true.obs;

  // Yorumlar
  var ratings = <RatingModel>[].obs;
  late final Stream<QuerySnapshot> _ratingStream;
  var isLoadingRatings = true.obs;

  @override
  void onInit() {
    super.onInit();
    _orderStream = FirebaseFirestore.instance
        .collection('siparisler')
        .orderBy('tarih', descending: true)
        .snapshots();
    _orderStream.listen((snapshot) {
      orders.value = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return OrderModel.fromMap(data);
      }).toList();
      isLoading.value = false;
    });

    // Yorumları dinle
    _ratingStream = FirebaseFirestore.instance
        .collection('ratings')
        .orderBy('timestamp', descending: true)
        .snapshots();
    _ratingStream.listen((snapshot) {
      ratings.value = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return RatingModel.fromMap(data, doc.id);
      }).toList();
      isLoadingRatings.value = false;
    });
  }

  void selectGroup(int idx) {
    selectedGroupIdx.value = idx;
    showTeslimEdildi.value = false;
  }

  void showTeslimEdildiView() {
    showTeslimEdildi.value = true;
  }

  Future<void> updateOrderStatus(String id, String? currentStatus) async {
    // Teslim edilen siparişlerin durumu değiştirilemez
    if (currentStatus == 'teslim edildi') {
      print("Teslim edilen sipariş durumu değiştirilemez");
      return;
    }
    
    String nextStatus = 'hazırlandı';
    if (currentStatus == null || currentStatus == 'hazırlanıyor') {
      nextStatus = 'hazırlandı';
    } else if (currentStatus == 'hazırlandı') {
      nextStatus = 'teslim edildi';
    }
    
    // Ana sipariş koleksiyonunu güncelle
    await FirebaseFirestore.instance.collection('siparisler').doc(id).update({
      'status': nextStatus,
    });
    
    // Kullanıcı geçmişini de güncelle
    await _updateUserHistoryStatus(id, nextStatus);
    
    // Eğer sipariş teslim edildiyse kullanıcı geçmişine kalıcı kayıt
    if (nextStatus == 'teslim edildi') {
      await _saveToUserHistory(id);
    }
  }
  
  // Kullanıcı geçmişindeki sipariş durumunu güncelleme
  Future<void> _updateUserHistoryStatus(String orderId, String newStatus) async {
    try {
      // Önce siparişin userId'sini bul
      final orderDoc = await FirebaseFirestore.instance.collection('siparisler').doc(orderId).get();
      if (!orderDoc.exists) {
        print("Sipariş bulunamadı: $orderId");
        return;
      }
      
      final orderData = orderDoc.data();
      final userId = orderData?['userId'] as String?;
      
      if (userId == null) {
        print("Sipariş userId bilgisi yok: $orderId");
        return;
      }
      
      // Kullanıcı geçmişindeki sipariş durumunu güncelle
      await FirebaseFirestore.instance
          .collection('user_order_history')
          .doc(userId)
          .collection('orders')
          .doc(orderId)
          .update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print("Kullanıcı geçmişi güncellendi: $orderId -> $newStatus");
    } catch (e) {
      print("Kullanıcı geçmişi güncellenirken hata: $e");
    }
  }
  
  // Sipariş teslim edildiğinde kullanıcı geçmişine kalıcı kayıt
  Future<void> _saveToUserHistory(String orderId) async {
    try {
      // Önce siparişin tam bilgilerini al
      final orderDoc = await FirebaseFirestore.instance.collection('siparisler').doc(orderId).get();
      if (!orderDoc.exists) {
        print("Sipariş bulunamadı: $orderId");
        return;
      }
      
      final orderData = orderDoc.data();
      final userId = orderData?['userId'] as String?;
      
      if (userId == null) {
        print("Sipariş userId bilgisi yok: $orderId");
        return;
      }
      
             // Kullanıcı geçmişine kalıcı kayıt
       await FirebaseFirestore.instance
           .collection('user_order_history')
           .doc(userId)
           .collection('orders')
           .doc(orderId)
           .set({
         ...(orderData ?? {}),
         'status': 'teslim edildi', // Durumu kesin olarak teslim edildi yap
         'savedAt': FieldValue.serverTimestamp(),
         'originalOrderId': orderId,
       });
      
      print("Sipariş kullanıcı geçmişine kaydedildi: $orderId");
    } catch (e) {
      print("Kullanıcı geçmişine kaydetme hatası: $e");
    }
  }

  Future<void> deleteOrder(String id) async {
    // Önce siparişin durumunu kontrol et
    final orderDoc = await FirebaseFirestore.instance.collection('siparisler').doc(id).get();
    if (orderDoc.exists) {
      final orderData = orderDoc.data();
      final status = orderData?['status'] as String?;
      
      // Teslim edilen siparişleri silme
      if (status == 'teslim edildi') {
        print("Teslim edilen sipariş silinemez");
        return;
      }
    }
    
    await FirebaseFirestore.instance.collection('siparisler').doc(id).delete();
  }

  Future<void> deleteRating(String id) async {
    await FirebaseFirestore.instance.collection('ratings').doc(id).delete();
  }

  List<RatingModel> getRatingsByFloor(int floor) {
    return ratings.where((rating) => rating.userFloor == floor).toList();
  }
}
