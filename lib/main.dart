

// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:task_management_application/firebase_options.dart';
// import 'package:task_management_application/modules/Notification/presentation/widgets/notification_service.dart';
// import 'package:task_management_application/splash_screen.dart';

// final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//     FlutterLocalNotificationsPlugin();
//     Future<void> _bgHandler(RemoteMessage message) async {
//   await Firebase.initializeApp();
// }


// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//       options: DefaultFirebaseOptions.currentPlatform);

//   FirebaseMessaging.onBackgroundMessage(_bgHandler);

//   const AndroidInitializationSettings androidSettings =
//       AndroidInitializationSettings('@mipmap/ic_launcher');

//   const InitializationSettings initSettings =
//       InitializationSettings(android: androidSettings);

//   await flutterLocalNotificationsPlugin.initialize(initSettings);

//   await NotificationService.init(flutterLocalNotificationsPlugin);

//   await FirebaseMessaging.instance.requestPermission(
//     alert: true,
//     badge: true,
//     sound: true,
//   );

//   FirebaseMessaging.onMessage.listen((message) {
//     NotificationService.showForegroundNotification(
//       message,
//       flutterLocalNotificationsPlugin,
//     );
//   });

//   runApp(const MyApp());
// }


// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Task Management',
//       debugShowCheckedModeBanner: false,
//       home: SplashScreen(),
//     );
//   }
// }


import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:task_management_application/firebase_options.dart';
import 'package:task_management_application/modules/Notification/presentation/widgets/notification_service.dart';
import 'package:task_management_application/splash_screen.dart';

/// ==============================
/// LOCAL NOTIFICATION INSTANCE
/// ==============================
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// ==============================
/// BACKGROUND MESSAGE HANDLER
/// ==============================
Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

/// ==============================
/// NOTIFICATION CLICK HANDLER
/// ==============================
void _handleNotificationClick(RemoteMessage message) {
  final data = message.data;
  debugPrint('🔔 Notification clicked: $data');

  // NOTE:
  // Do NOT navigate directly here.
  // Store data if needed & navigate after Splash/Login.

  if (data['type'] == 'task_assigned') {
    debugPrint('➡ Navigate to employee task list');
  }

  if (data['type'] == 'task_completed') {
    debugPrint('➡ Navigate to admin dashboard');
  }
}

/// ==============================
/// MAIN
/// ==============================
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  /// 🔹 Background notifications
  FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler);

  /// 🔹 Android notification setup
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings =
      InitializationSettings(android: androidSettings);

  await flutterLocalNotificationsPlugin.initialize(initSettings);

  /// 🔹 Create notification channel
  await NotificationService.init(flutterLocalNotificationsPlugin);

  /// 🔹 Request permission
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  /// 🔹 Foreground notification
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    NotificationService.showForegroundNotification(
      message,
      flutterLocalNotificationsPlugin,
    );
  });

  /// 🔹 App opened from BACKGROUND by tapping notification
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    _handleNotificationClick(message);
  });

  /// 🔹 App opened from TERMINATED state
  final RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();

  if (initialMessage != null) {
    _handleNotificationClick(initialMessage);
  }

  runApp(const MyApp());
}

/// ==============================
/// APP ROOT
/// ==============================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Management',
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
