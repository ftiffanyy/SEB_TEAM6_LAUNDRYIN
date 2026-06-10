import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Import service, model, dan view milikmu
import 'firestore_service.dart';
import '../views/customer/customer_order_detail_page.dart';
import '../viewmodels/customer_dashboard_viewmodel.dart';
import '../models/order_detail_model.dart';
import '../models/service_model.dart';

class NotificationService {
  // GlobalKey agar bisa pindah halaman dari mana saja tanpa BuildContext
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _firestoreService = FirestoreService();

  Future<void> initNotifications() async {
    // 1. Minta izin notifikasi (Wajib untuk Android 13+ & iOS)
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Handling saat notifikasi di-tap ketika aplikasi ada di BACKGROUND
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationClick(message);
    });

    // 3. Handling saat notifikasi di-tap ketika aplikasi MATI TOTAL (TERMINATED)
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      // Diberi delay 1 detik agar memastikan MaterialApp selesai dirender terlebih dahulu
      Future.delayed(const Duration(seconds: 1), () {
        _handleNotificationClick(initialMessage);
      });
    }
  }

  // Fungsi otomatis untuk mengumpulkan data Firestore & Navigasi
  Future<void> _handleNotificationClick(RemoteMessage message) async {
    Map<String, dynamic> data = message.data;
    
    // Kita gunakan 'order_code' sebagai acuan (sesuai payload dari backend nanti)
    String? orderCode = data['order_code']; 

    if (orderCode != null) {
      final context = navigatorKey.currentContext;
      
      try {
        // Tampilkan loading spinner secara global agar user tahu data sedang dimuat
        if (context != null) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );
        }

        // Jalankan pencarian data (Meniru logika _trackOrder di login_page kamu)
        final order = await _firestoreService.getOrderByCode(orderCode);
        if (order == null) {
          if (context != null) Navigator.pop(context); // Tutup loading jika data zonk
          return;
        }

        final orderDetails = await _firestoreService.getOrderDetails();
        final services = await _firestoreService.getServices();

        final detail = orderDetails.firstWhere(
          (d) => d.orderId == order.orderId,
          orElse: () => OrderDetailModel(
            orderDetailId: 0,
            orderId: order.orderId,
            serviceId: 0,
            weight: 0,
          ),
        );

        final service = services.firstWhere(
          (s) => s.serviceId == detail.serviceId,
          orElse: () => ServiceModel(
            serviceId: 0,
            serviceName: 'Unknown Service',
            estimatedDays: 0,
            servicePrice: 0,
            description: 'No description',
            isActive: false,
          ),
        );

        // Bungkus data menjadi objek CustomerOrderItem yang siap saji
        final item = CustomerOrderItem(
          order: order,
          serviceName: service.serviceName,
          estimatedDays: service.estimatedDays,
          servicePrice: service.servicePrice,
        );

        // Tutup loading spinner
        if (context != null) Navigator.pop(context);

        // Langsung arahkan ke halaman detail pesanan bawaanmu
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => CustomerOrderDetailPage(item: item),
          ),
        );
      } catch (e) {
        debugPrint("Error FCM Navigation: $e");
        if (context != null) Navigator.of(context).pop(); // Amankan jika crash
      }
    }
  }

  // Fungsi untuk update FCM Token ke data User di Firestore
  Future<void> saveDeviceToken(String userId) async {
    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        // Disamakan menjadi 'fcm_token' sesuai rancangan UserModel kamu
        await _db.collection('users').doc(userId).set({
          'fcm_token': token, 
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint("FCM Token sukses diperbarui untuk User ID: $userId");
      }
    } catch (e) {
      debugPrint("Gagal menyimpan FCM Token: $e");
    }
  }
}