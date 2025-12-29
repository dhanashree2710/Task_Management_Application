import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_management_application/modules/Employee/presentation/views/employee_dashboard.dart';
import 'package:task_management_application/utils/components/kdrt_colors.dart';
import 'package:task_management_application/modules/Task/presentation/views/employee_task_list.dart'; // make sure this import is correct

class NotificationHistoryScreen extends StatelessWidget {
  final String currentUserId;
final String currentUserRole;

  const NotificationHistoryScreen({
    super.key,
    required this.currentUserId, required this.currentUserRole,
  });

  @override
  Widget build(BuildContext context) {
    final userRef =
        FirebaseFirestore.instance.doc('users/$currentUserId');

    print("📢 Notification screen opened for: $currentUserId");

    return Scaffold(
      backgroundColor: KDRTColors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(65),
        child: AppBar(
          automaticallyImplyLeading: false,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF42A5F5), Color(0xFF1565C0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          elevation: 0,
          titleSpacing: 0,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: AssetImage('assets/logo.png'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('user_ref', isEqualTo: userRef)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // 🔄 Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ❌ Error
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          // 📭 Empty
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No notifications",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final docs = snapshot.data!.docs;
          print("📦 Notifications found: ${docs.length}");

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return ListTile(
                leading: Icon(
                  Icons.notifications,
                  color: data['is_read'] == true
                      ? Colors.white
                      : Colors.blue,
                ),
                title: Text(
                  data['title'] ?? '',
                  style: TextStyle(
                    fontWeight: data['is_read'] == true
                        ? FontWeight.normal
                        : FontWeight.bold,
                  ),
                ),
                subtitle: Text(data['message'] ?? ''),
                trailing: data['is_read'] == true
                    ? null
                    : const Icon(
                        Icons.circle,
                        color: Colors.red,
                        size: 10,
                      ),
                onTap: () async {
                  // ✅ Mark as read
                  await FirebaseFirestore.instance
                      .collection('notifications')
                      .doc(doc.id)
                      .update({'is_read': true});

                  // 🔜 Navigate to task using task_ref
                  final taskRef = data['task_ref'] as DocumentReference?;
                  if (taskRef == null) return;

                  final taskId = taskRef.id;

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EmployeeDashboardScreen(
                        currentUserId: currentUserId,
                        currentUserRole: currentUserRole,
                       // highlightTaskId: taskId, // Optional: highlight this task
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
