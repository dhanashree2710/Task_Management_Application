import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LeaveApplicationsScreen extends StatefulWidget {
  const LeaveApplicationsScreen({super.key});

  @override
  State<LeaveApplicationsScreen> createState() =>
      _LeaveApplicationsScreenState();
}

class _LeaveApplicationsScreenState extends State<LeaveApplicationsScreen> {
  final LeaveService _leaveService = LeaveService();
  bool isLoading = true;
  List<Map<String, dynamic>> applications = [];

  @override
  void initState() {
    super.initState();
    loadAllApplications();
  }

  Future<void> loadAllApplications() async {
    setState(() => isLoading = true);
    applications = await _leaveService.fetchAllLeaveApplications();
    setState(() => isLoading = false);
  }

  // 🔥 Format date dd-MM-yyyy
  String formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return "-";
    try {
      DateTime dt = DateTime.parse(rawDate);
      return "${dt.day.toString().padLeft(2, '0')}-"
          "${dt.month.toString().padLeft(2, '0')}-"
          "${dt.year}";
    } catch (e) {
      return rawDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    int crossAxisCount = width > 1100
        ? 3
        : width > 700
            ? 2
            : 1;

    return Scaffold(
      backgroundColor: const Color(0xfff2f5f9),

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
          : applications.isEmpty
              ? const Center(child: Text("No applications found"))
              : Column(
                  children: [
                    const SizedBox(height: 10),

                    // 🔥 Gradient title
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color(0xFF34D0C6),
                            Color(0xFF22A4E0),
                            Color(0xFF1565C0)
                          ],
                        ).createShader(bounds),
                        child: const Text(
                          "Leave Applications",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(14),
                        itemCount: applications.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: width > 1100
                              ? 1.1
                              : width > 700
                                  ? 0.95
                                  : 0.85,
                        ),
                        itemBuilder: (context, index) {
                          return _animatedCard(applications[index]);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  // 🔥 Animation wrapper
  Widget _animatedCard(Map<String, dynamic> app) {
    return AnimatedOpacity(
      opacity: 1,
      duration: const Duration(milliseconds: 600),
      child: TweenAnimationBuilder(
        duration: const Duration(milliseconds: 600),
        tween: Tween<double>(begin: 50, end: 0),
        curve: Curves.easeOut,
        builder: (context, value, child) => Transform.translate(
          offset: Offset(0, value),
          child: child,
        ),
        child: _buildCard(app),
      ),
    );
  }

  // 🔥 MAIN CARD UI
  Widget _buildCard(Map<String, dynamic> app) {
    // Smart status key detector
    String status = (app['status'] ??
            app['Status'] ??
            app['leave_status'] ??
            app['LeaveStatus'] ??
            "pending")
        .toString()
        .toLowerCase();

    // Colors based on status
    Color borderClr = status == "approved"
        ? Colors.green
        : status == "rejected"
            ? Colors.red
            : Colors.orange;

    Color chipColor = borderClr;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF42A5F5), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(2),

      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(color: borderClr, width: 6),
          ),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 👤 Name
            Text(
              app['userName'] ?? "Unknown User",
              style: const TextStyle(
                  fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),

            Text("Applied: ${formatDate(app['appliedOn'])}"),
            const SizedBox(height: 6),

            Text(
              app['leaveType'] ?? "-",
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),
            Text("From: ${formatDate(app['startDate'])}"),
            Text("To: ${formatDate(app['endDate'])}"),
            Text("Reason: ${app['reason'] ?? '-'}"),

            const Spacer(),

            // 🔥 Pending -> buttons, else -> chip
            status == "pending"
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          await _leaveService.updateStatus(
                            app['userId'],
                            app['applicationId'],
                            "approved",
                          );
                          loadAllApplications();
                        },
                        child: const Text("Approve"),
                      ),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          await _leaveService.updateStatus(
                            app['userId'],
                            app['applicationId'],
                            "rejected",
                          );
                          loadAllApplications();
                        },
                        child: const Text("Reject"),
                      ),
                    ],
                  )
                : Chip(
                    label: Text(
                      status.toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: chipColor,
                  ),
          ],
        ),
      ),
    );
  }
}

// 🔥 SERVICE CLASS
class LeaveService {
  Future<List<Map<String, dynamic>>> fetchAllLeaveApplications() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collectionGroup("applications").get();

      List<Map<String, dynamic>> result = [];

      for (var doc in snapshot.docs) {
        String userId = doc.reference.parent.parent?.id ?? "";

        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection("users")
            .doc(userId)
            .get();

        String userName = userDoc['user_name'] ?? "Unknown";

        result.add({
          "applicationId": doc.id,
          "userId": userId,
          "userName": userName,
          ...doc.data() as Map<String, dynamic>,
        });
      }

      return result;
    } catch (e) {
      print("Fetch Error: $e");
      return [];
    }
  }

  Future<void> updateStatus(
      String userId, String applicationId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection("leave_applications")
          .doc(userId)
          .collection("applications")
          .doc(applicationId)
          .update({"status": status});

      print("Status updated: $status");
    } catch (e) {
      print("Update Error: $e");
    }
  }
}
