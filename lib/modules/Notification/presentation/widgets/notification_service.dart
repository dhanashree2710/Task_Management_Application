// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:cloud_functions/cloud_functions.dart';

// class NotificationService {
//   // Save token and subscribe to role topic
//   static Future<void> saveTokenAndSubscribe(String userId, String role) async {
//     final token = await FirebaseMessaging.instance.getToken();
//     if (token != null) {
//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(userId)
//           .update({'fcm_token': token});
//     }
//     await FirebaseMessaging.instance.subscribeToTopic(role);
//   }

//   // Send push notification via Cloud Function
//   static Future<void> sendPushNotification({
//     required String token,
//     required String title,
//     required String body,
//     required Map<String, dynamic> payload,
//   }) async {
//     final callable =
//         FirebaseFunctions.instance.httpsCallable('sendPushNotification');
//     await callable.call({
//       'token': token,
//       'title': title,
//       'body': body,
//       'payload': payload,
//     });
//   }

//   // Show notification when app is in foreground
//   static void showForegroundNotification(
//       RemoteMessage message,
//       FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) {
//     flutterLocalNotificationsPlugin.show(
//       0,
//       message.notification?.title,
//       message.notification?.body,
//       const NotificationDetails(
//         android: AndroidNotificationDetails(
//           'task_channel',
//           'Task Notifications',
//           importance: Importance.max,
//           priority: Priority.high,
//         ),
//       ),
//     );
//   }
// }
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static const AndroidNotificationChannel _channel =
      AndroidNotificationChannel(
    'task_channel',
    'Task Notifications',
    description: 'Notifications for task updates',
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('notification'),
  );

  /// 🔹 Create notification channel (call once in main)
  static Future<void> init(
      FlutterLocalNotificationsPlugin plugin) async {
    await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  /// 🔹 Save FCM token
  static Future<void> saveToken(String userId) async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'fcm_token': token});
    }
  }

  /// 🔹 CALL CLOUD FUNCTION (THIS IS IMPORTANT)
  static Future<void> sendPushNotification({
    required String token,
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) async {
    final callable =
        FirebaseFunctions.instance.httpsCallable('sendPushNotification');

    await callable.call({
      'token': token,
      'title': title,
      'body': body,
      'payload': payload,
    });
  }

  /// 🔹 Foreground notification only
  static void showForegroundNotification(
    RemoteMessage message,
    FlutterLocalNotificationsPlugin plugin,
  ) {
    plugin.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          sound: _channel.sound,
        ),
      ),
    );
  }
}
