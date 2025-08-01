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
    String nextStatus = 'hazırlandı';
    if (currentStatus == null || currentStatus == 'hazırlanıyor') {
      nextStatus = 'hazırlandı';
    } else if (currentStatus == 'hazırlandı') {
      nextStatus = 'teslim edildi';
    } else if (currentStatus == 'teslim edildi') {
      nextStatus = 'teslim edildi';
    }
    await FirebaseFirestore.instance.collection('siparisler').doc(id).update({
      'status': nextStatus,
    });
  }

  Future<void> deleteOrder(String id) async {
    await FirebaseFirestore.instance.collection('siparisler').doc(id).delete();
  }

  Future<void> deleteRating(String id) async {
    await FirebaseFirestore.instance.collection('ratings').doc(id).delete();
  }

  List<RatingModel> getRatingsByFloor(int floor) {
    return ratings.where((rating) => rating.userFloor == floor).toList();
  }
}
