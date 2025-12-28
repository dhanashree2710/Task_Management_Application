import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EmployeeLeaveHistoryScreen extends StatefulWidget {
  final String currentUserId;

  const EmployeeLeaveHistoryScreen({
    super.key,
    required this.currentUserId,
  });

  @override
  State<EmployeeLeaveHistoryScreen> createState() =>
      _EmployeeLeaveHistoryScreenState();
}

class _EmployeeLeaveHistoryScreenState
    extends State<EmployeeLeaveHistoryScreen> {

  bool isLoading = true;
  List<Map<String, dynamic>> leaves = [];

  @override
  void initState() {
    super.initState();
    fetchMyLeaves();
  }

  Future<void> fetchMyLeaves() async {
    print("🔑 Current User ID: ${widget.currentUserId}");
    setState(() => isLoading = true);

    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance
              .collectionGroup("applications")
              .get();

      List<Map<String, dynamic>> temp = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print("🧾 RAW DATA: $data");

        if (data['userId'] == widget.currentUserId) {
          temp.add({
            "applicationId": doc.id,
            ...data,
          });
        }
      }

      // 🔥 Sort by appliedOn (string date)
      temp.sort((a, b) =>
          b['appliedOn'].toString().compareTo(
              a['appliedOn'].toString()));

      print("📄 Total Leaves Found: ${temp.length}");

      setState(() {
        leaves = temp;
        isLoading = false;
      });
    } catch (e) {
      print("❌ Fetch Error: $e");
      setState(() => isLoading = false);
    }
  }

Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case "approved":
      return Colors.green;
    case "rejected":
      return Colors.red;
    default:
      return Colors.orange;
  }
}

IconData _statusIcon(String status) {
  switch (status.toLowerCase()) {
    case "approved":
      return Icons.check_circle;
    case "rejected":
      return Icons.cancel;
    default:
      return Icons.hourglass_bottom;
  }
}

// 🔥 Convert "2025-12-08 21:26" → "08 Dec 2025, 9:26 PM"
String formatDateTime12(String raw) {
  try {
    DateTime dt = DateTime.parse(raw);
    return DateFormat('dd MMM yyyy, h:mm a').format(dt);
  } catch (_) {
    return raw;
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 6,
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
        titleSpacing: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12.0),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: AssetImage('assets/logo.png'),
              ),
            ),
          ],
        ),
      ),


      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : leaves.isEmpty
              ? const Center(child: Text("No leave records found"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: leaves.length,
                  itemBuilder: (context, index) {
                    final app = leaves[index];

                    print("📘 Rendering card: ${app['leaveType']}");

                  return Card(
  elevation: 3,
  margin: const EdgeInsets.only(bottom: 16),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
    side: BorderSide(
      color: _statusColor(app['status']), // 🔥 OUTLINE BY STATUS
      width: 1.6,
    ),
  ),

  child: Padding(
    padding: const EdgeInsets.all(16),

    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // 🔹 Leave Type + Status (NO OVERFLOW)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 🔥 Wrap text safely
            Expanded(
              child: Text(
                app['leaveType'] ?? "-",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(width: 8),

            Chip(
              avatar: Icon(
                _statusIcon(app['status']),
                size: 18,
                color: Colors.white,
              ),
              label: Text(
                app['status'].toString().toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: _statusColor(app['status']),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // 🔹 Date Range
        Row(
          children: [
            const Icon(Icons.date_range, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "${app['startDate']} → ${app['endDate']}",
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        // 🔹 Applied On (12-hour format)
        Row(
          children: [
            const Icon(Icons.schedule, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Applied: ${formatDateTime12(app['appliedOn'])}",
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        const Divider(height: 22),

        // 🔹 Reason
        Text(
          "Reason",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          app['reason'] ?? "-",
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  ),
);

                  },
                ),
    );
  }
}
