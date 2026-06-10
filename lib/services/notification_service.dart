import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;

import '../services/firestore_service.dart';
import '../views/customer/customer_order_detail_page.dart';
import '../viewmodels/customer_dashboard_viewmodel.dart';
import '../models/order_detail_model.dart';
import '../models/service_model.dart';

class NotificationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> initNotifications() async {
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      Future.delayed(
        const Duration(seconds: 1),
        () => _handleMessage(initialMessage),
      );
    }
  }

  Future<void> _handleMessage(RemoteMessage message) async {
    final data = message.data;
    final orderCode = data['order_code'];

    if (orderCode == null) return;

    final context = navigatorKey.currentContext;

    try {
      if (context != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );
      }

      final order = await _firestoreService.getOrderByCode(orderCode);
      if (order == null) {
        if (context != null) Navigator.pop(context);
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
          serviceName: 'Unknown',
          estimatedDays: 0,
          servicePrice: 0,
          description: '',
          isActive: false,
        ),
      );

      if (context != null) Navigator.pop(context);

      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => CustomerOrderDetailPage(
            item: CustomerOrderItem(
              order: order,
              serviceName: service.serviceName,
              estimatedDays: service.estimatedDays,
              servicePrice: service.servicePrice,
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint("FCM Error: $e");
      if (context != null) Navigator.pop(context);
    }
  }

  /// SAVE TOKEN (FIXED - tidak duplikat user_ dan 9)
  Future<void> saveDeviceToken(String userId) async {
    try {
      debugPrint("=== SAVE DEVICE TOKEN START ===");

      String? token = await _fcm.getToken();

      debugPrint("DEVICE TOKEN: $token");

      if (token == null) {
        debugPrint("TOKEN NULL - FCM ERROR");
        return;
      }

      await _db.collection('users').doc('user_$userId').set({
        'fcm_token': token,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint("TOKEN SAVED TO: users/user_$userId");

      // 🔥 CEK LANGSUNG SETELAH SAVE
      final check = await _db.collection('users').doc('user_$userId').get();

      debugPrint("FIRESTORE AFTER SAVE: ${check.data()}");

      debugPrint("=== SAVE DEVICE TOKEN END ===");
    } catch (e) {
      debugPrint("ERROR SAVE TOKEN: $e");
    }
  }

  Future<void> sendStatusNotification({
    required String fcmToken,
    required String orderCode,
    required String newStatus,
  }) async {
    try {
      const projectId = 'laundryin-73d4f';

      final url = Uri.parse(
        'https://fcm.googleapis.com/v1/projects/$projectId/messages:send',
      );

      final accessToken = await _getAccessToken();

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          "message": {
            "token": fcmToken,
            "notification": {
              "title": "Laundry Update 🧺",
              "body": "Order $orderCode updated to $newStatus",
            },
            "data": {
              "order_code": orderCode,
              "status": newStatus,
            }
          }
        }),
      );

      debugPrint("FCM response: ${response.body}");
    } catch (e) {
      debugPrint("Send notif error: $e");
    }
  }

  Future<String> _getAccessToken() async {
    final credentials = auth.ServiceAccountCredentials.fromJson({
      "type": "service_account",
      "project_id": "laundryin-73d4f",
      "private_key_id": "8967f7403271b6caad68c11cc7e459c367115da6",
      "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDIi8QC1DkLYhnD\nTFsN43xe04bpdGdNRBgj8qMex5qA6N/3Cqb1KwNz7w9oNrXoDLs5y+Y1+gfYMpc6\n3Xye0T9W99HAp3kIc8zTcVRuABBIYSIz+MIQ50lUAyWrsREqDzI3JfK9MGhMJ88C\n2gI4bSQ97hYqE5Zl5ii+jCOfEsVUaQSRh70moZ40Sa4IpVfM0i+g8JJvaA3VnhQ9\naHmMq9tmIqkTLnFmOFamPfia0XKIW2tS+tojR97QN/0lVy0v88YtHQeW0wU7T3KV\nTWn+ZMB/lEJDZxDxfu+bx1lBvvz2xuhd80F5eP3wLhC7X6WDEBDvQPU2vuKTci2p\nTRwOVIwFAgMBAAECggEAKX25LPipYLCIMf6/K+1v0tKiq/Q4VyUKdY2CsCCN17PW\nem8KwdiHW1oPbvk6w2q25atI0swLCXDWFwix+s3B9AVLsTc09Em5C9n7pNKAi+kE\nwYnq5MJlSmtoRNBag8AnHH/Oa9PzECaATs+5++CgyetTTJtG14g5z8qAqC2jA+Zk\nkfeWNAhP3hfMQ5CCpp6tsHMS/ubozBtnBvt8UuLqRXCb9YxrMXQ2zz0aryb8FLC4\nDxyL4kqD0tENcuHbW3lkP2lLF7xyQ2IIj/P0gCND9CreyTqKYlQC8svKtTkvcXpn\nMiDYZUaFSwqgK6njiIJQmdGlK9kxBhI08pe3eRQLQQKBgQDoBqqf+YS3UICMXtoh\nm2ISrnGL4voLajaugeZ3j1Th7R1ouOnjRbxlUwVMCWJl1E15a58ajgYYie8raqRc\nVITEJSeHZyk2ei4kiLqkqCQsOTTRmFdWFIAtNLOqfQz/sSJktoJDCuLpiD4AsEYm\n6Nc3RbYJ2kklS+y63NIucZYgVQKBgQDdRGr1pdMjTLEXBtdFsQaacXPqXElPwOjg\ngTbWw+aiAwUclw5CiC/PzcHSuHwcSS0QjMcG9EZSkaN/PelutdjuuFlLEy5xWya0\nqiPIc1BODOKafI1/+kVxS74uuInMlfGvUIPYdgus37eDAD4Bb7mc4jK/dG5ltPeG\nFFhzhCus8QKBgQC9+S9cujSyzwPhaowY9hsvhorLaTUngXhyG0Oy4rUyIi1xH+3I\nOsHNCFOO9SQOkew5HSfw2xYco1si5jbargzieDVMROfWheUf3p9Kz6yGVPRtI9lm\nTnTADqWIUskA1Wx+n3w6HkC5yuZRNALMOtpzk+0/Ve2LzwVt3f1tL20m3QKBgHRW\nds51w8+5kRsEU8emzkwB/upoX3t5eHgiOE0vb2IbqGJh4fOFW24tRw2eRlMw/mrH\nOhYj9Z2QSaCrUsMNBeRuNTTN/wtG29D97BaG2uBO0g5cEqIJWt2472PtTzasWAjP\nkqMLXhQlBH3ycKecsMEWBYy4kRsUzVhH9kG2aqhhAoGAaj2ryWV9kiSmdiRXRNqz\nknYszmF9ycGXXljnPDxK+LmlWvdCEFiDwi1imb9uFgG8v8U24kjFXTn7SxuRB+nE\nFHk5BCF/WxSU5UMgm4NKWHXqeM3W/n6pQFtkb47Asv7pxjD6cs/5T98B3ynK9Lpa\n2Wfui5NsjGJWgYsFTIBam3E=\n-----END PRIVATE KEY-----\n",
      "client_email": "firebase-adminsdk-fbsvc@laundryin-73d4f.iam.gserviceaccount.com",
      "client_id": "100324600157342299312",
      "token_uri": "https://oauth2.googleapis.com/token",
    });

    final client = await auth.clientViaServiceAccount(
      credentials,
      ['https://www.googleapis.com/auth/firebase.messaging'],
    );

    final token = client.credentials.accessToken.data;
    client.close();
    return token;
  }
}