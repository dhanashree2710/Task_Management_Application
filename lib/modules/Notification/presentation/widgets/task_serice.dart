import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_management_application/modules/Notification/presentation/widgets/whatapp_service.dart';
import 'notification_service.dart';

class TaskService {
  /// 🧑‍💼 Assign task
  static Future<void> assignTask({
    required String taskTitle,
    required String employeeId,
    required String employeePhone,
    required String taskId,
    required String adminId,
  }) async {
    // 1️⃣ Save task
    await FirebaseFirestore.instance.collection('tasks').doc(taskId).set({
      'title': taskTitle,
      'assigned_to': employeeId,
      'assigned_by': adminId,
      'status': 'assigned',
      'created_at': FieldValue.serverTimestamp(),
    });

    // 2️⃣ Get employee FCM token
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(employeeId)
        .get();

    final String? token = userDoc.data()?['fcm_token'];

    // 3️⃣ Send push notification
    if (token != null && token.isNotEmpty) {
      await NotificationService.sendPushNotification(
        token: token,
        title: "New Task Assigned",
        body: "You have been assigned: $taskTitle",
        payload: {
          'type': 'task_assigned',
          'task_id': taskId,
          'user_id': employeeId,
        },
      );
    }

    // 4️⃣ WhatsApp
    await WhatsAppService.sendMessage(
      employeePhone,
      "New Task Assigned: $taskTitle",
    );
  }

  /// ✅ Complete task
  static Future<void> completeTask({
    required String taskId,
    required String adminId,
    required String taskTitle,
    required String adminPhone,
  }) async {
    await FirebaseFirestore.instance
        .collection('tasks')
        .doc(taskId)
        .update({'status': 'completed'});

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(adminId)
        .get();

    final String? token = userDoc.data()?['fcm_token'];

    if (token != null && token.isNotEmpty) {
      await NotificationService.sendPushNotification(
        token: token,
        title: "Task Completed",
        body: "Task completed: $taskTitle",
        payload: {
          'type': 'task_completed',
          'task_id': taskId,
          'user_id': adminId,
        },
      );
    }

    await WhatsAppService.sendMessage(
      adminPhone,
      "Task Completed: $taskTitle",
    );
  }
}
