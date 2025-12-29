// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:task_management_application/firebase_options.dart';
// import 'package:task_management_application/modules/Notification/presentation/widgets/notification_service.dart';
// import 'package:task_management_application/splash_screen.dart';



// final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//     FlutterLocalNotificationsPlugin();


// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//    FirebaseMessaging.onBackgroundMessage(_bgHandler);

//   // Initialize Flutter Local Notifications
//   const AndroidInitializationSettings androidSettings =
//       AndroidInitializationSettings('@mipmap/ic_launcher');
//   const InitializationSettings initSettings =
//       InitializationSettings(android: androidSettings);
//   await flutterLocalNotificationsPlugin.initialize(initSettings,
//       onDidReceiveNotificationResponse: (payload) {
//     // Handle notification click if needed
//   });
//   FirebaseMessaging.onMessage.listen((message) {
//   NotificationService.showForegroundNotification(
//     message,
//     flutterLocalNotificationsPlugin
//   );
// });

//   runApp(const MyApp());
// }

// Future<void> _bgHandler(RemoteMessage message) async {
//   await Firebase.initializeApp();
// }
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

  
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Task Management',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
        
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
//       ),
//  // home: AdminRegistration(currentUserId: '', currentUserRole: '',),
//   // home: EmployeeTaskListScreen(currentUserId: '', currentUserRole: '',),
//   home: SplashScreen(),
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

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
    Future<void> _bgHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_bgHandler);

  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings =
      InitializationSettings(android: androidSettings);

  await flutterLocalNotificationsPlugin.initialize(initSettings);

  await NotificationService.init(flutterLocalNotificationsPlugin);

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  FirebaseMessaging.onMessage.listen((message) {
    NotificationService.showForegroundNotification(
      message,
      flutterLocalNotificationsPlugin,
    );
  });

  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Management',
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}
