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
      body: Column(
  children: [
    // 🔘 ACTION BUTTONS
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ✅ MARK ALL AS READ
          ElevatedButton.icon(
            icon: const Icon(Icons.done_all, size: 18),
            label: const Text("Mark all read"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onPressed: () async {
              final batch = FirebaseFirestore.instance.batch();

              final snapshot = await FirebaseFirestore.instance
                  .collection('notifications')
                  .where('user_ref', isEqualTo: userRef)
                  .where('is_read', isEqualTo: false)
                  .get();

              for (var doc in snapshot.docs) {
                batch.update(doc.reference, {'is_read': true});
              }

              await batch.commit();
            },
          ),

          // ❌ CLEAR ALL
          ElevatedButton.icon(
            icon: const Icon(Icons.delete, size: 18),
            label: const Text("Clear all"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onPressed: () async {
              final snapshot = await FirebaseFirestore.instance
                  .collection('notifications')
                  .where('user_ref', isEqualTo: userRef)
                  .get();

              final batch = FirebaseFirestore.instance.batch();

              for (var doc in snapshot.docs) {
                batch.delete(doc.reference);
              }

              await batch.commit();
            },
          ),
        ],
      ),
    ),

    // 🔔 NOTIFICATION LIST
    Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('user_ref', isEqualTo: userRef)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No notifications"),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return ListTile(
                leading: Icon(
                  Icons.notifications,
                  color: data['is_read'] == true
                      ? Colors.grey
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
                    : const Icon(Icons.circle, color: Colors.red, size: 10),
                onTap: () async {
                  await FirebaseFirestore.instance
                      .collection('notifications')
                      .doc(doc.id)
                      .update({'is_read': true});

                  final taskRef = data['task_ref'] as DocumentReference?;
                  if (taskRef == null) return;

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EmployeeDashboardScreen(
                        currentUserId: currentUserId,
                        currentUserRole: currentUserRole,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    ),
  ],
),
    );
    

  }
}