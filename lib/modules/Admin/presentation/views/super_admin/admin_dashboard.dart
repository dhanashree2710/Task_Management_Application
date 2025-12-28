import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_management_application/modules/Employee/presentation/views/employee_list.dart';
import 'package:task_management_application/modules/Interns/presentation/views/interns_list.dart';
import 'package:task_management_application/modules/Task/presentation/views/employee_task_list.dart';
import 'package:task_management_application/utils/common/appbar_drawer.dart';
import 'package:task_management_application/utils/components/kdrt_colors.dart';

class AdminDashboard extends StatefulWidget {
  final String currentUserRole;
  const AdminDashboard({super.key, this.currentUserRole = "admin"});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String greeting = "";
  String formattedDate = "";
  String dayName = "";
  bool isLoading = true;

  int totalEmployees = 0;
  int totalInterns = 0;

  // Task status counts
  int totalTasks = 0;
  int pendingTasks = 0;
  int inProgressTasks = 0;
  int completedTasks = 0;

  @override
  void initState() {
    super.initState();
    _setGreeting();
    _fetchCounts();
  }

  void _setGreeting() {
    final hour = DateTime.now().hour;
    greeting =
        hour < 12
            ? "Good Morning"
            : hour < 17
            ? "Good Afternoon"
            : "Good Evening";

    formattedDate = DateFormat('MMMM dd, yyyy').format(DateTime.now());
    dayName = DateFormat('EEEE').format(DateTime.now());
  }

  Future<void> _fetchCounts() async {
    setState(() => isLoading = true);
    try {
      final empSnap =
          await FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'employee')
              .get();

      final internSnap =
          await FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'intern')
              .get();

      final taskSnap =
          await FirebaseFirestore.instance.collection('tasks').get();

      int pending = 0, progress = 0, complete = 0;

      for (var doc in taskSnap.docs) {
        final status = (doc['status'] ?? '').toString().toLowerCase();
        if (status.contains('pending'))
          pending++;
        else if (status.contains('progress'))
          progress++;
        else if (status.contains('complete'))
          complete++;
      }

      setState(() {
        totalEmployees = empSnap.docs.length;
        totalInterns = internSnap.docs.length;
        totalTasks = taskSnap.docs.length;
        pendingTasks = pending;
        inProgressTasks = progress;
        completedTasks = complete;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching counts: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.currentUserRole;
    return CommonScaffold(
      title:
          role == "super admin" ? "Super Admin Dashboard" : "Admin Dashboard",
      role: role,
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _fetchCounts,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Greeting + Refresh on same line
                    Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Row(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFF34D0C6),
              Color(0xFF22A4E0),
              Color(0xFF1565C0),
            ],
          ).createShader(bounds),
          child: Text(
            "$greeting, ${role == 'super admin' ? 'Super Admin' : 'Admin'} ",
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 6),
        const WavingHand(), // ✅ Animated & colored
      ],
    

                            
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.blue),
                            tooltip: "Refresh Data",
                            onPressed: _fetchCounts,
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Date + Day
                      Center(
                        child: Column(
                          children: [
                            Text(
                              formattedDate,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              dayName,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      // Dashboard cards
                      GridView.count(
                        crossAxisCount:
                            MediaQuery.of(context).size.width > 800 ? 3 : 1,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: 1.2,
                        children: [
                          _dashboardCard(
                            title: "Total Employees",
                            count: totalEmployees,
                            icon: Icons.people,
                            color: Colors.teal,
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => EmployeeListScreen(
                                          currentUserId:
                                              FirebaseAuth
                                                  .instance
                                                  .currentUser
                                                  ?.uid ??
                                              '',
                                          currentUserRole: role,
                                        ),
                                  ),
                                ),
                          ),
                          _dashboardCard(
                            title: "Total Interns",
                            count: totalInterns,
                            icon: Icons.school,
                            color: Colors.deepPurple,
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => InternListScreen(
                                          currentUserId:
                                              FirebaseAuth
                                                  .instance
                                                  .currentUser
                                                  ?.uid ??
                                              '',
                                          currentUserRole: role,
                                        ),
                                  ),
                                ),
                          ),
                          _taskCard(
                            totalTasks: totalTasks,
                            pending: pendingTasks,
                            inProgress: inProgressTasks,
                            completed: completedTasks,
                            color: Colors.blue,
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => EmployeeTaskListScreen(
                                          currentUserId:
                                              FirebaseAuth
                                                  .instance
                                                  .currentUser
                                                  ?.uid ??
                                              '',
                                          currentUserRole: role,
                                        ),
                                  ),
                                ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      Center(
                        child: Text(
                          "© 2025 KDRT IT Solutions — Admin Portal",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _dashboardCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color.withOpacity(0.8), color]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 50, color: color),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "$count",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: KDRTColors.darkBlue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  //   Widget _taskCard({
  //     required int totalTasks,
  //     required int pending,
  //     required int inProgress,
  //     required int completed,
  //     required Color color,
  //     required VoidCallback onTap,
  //   }) {
  //     return InkWell(
  //       onTap: onTap,
  //       borderRadius: BorderRadius.circular(20),
  //       child: Container(
  //         decoration: BoxDecoration(
  //           gradient: LinearGradient(colors: [color.withOpacity(0.8), color]),
  //           borderRadius: BorderRadius.circular(20),
  //           boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
  //         ),
  //         child: Container(
  //           margin: const EdgeInsets.all(2),
  //           decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
  //           child: Padding(
  //             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  //             child: Column(
  //               mainAxisAlignment: MainAxisAlignment.center,
  //               children: [
  //                 Icon(Icons.assignment, size: 50, color: color),
  //                 const SizedBox(height: 8),
  //                 Text("Tasks Overview", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
  //                 const SizedBox(height: 6),
  //                 Text("Total: $totalTasks", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
  //                 const Divider(),
  //                 Wrap(
  //   alignment: WrapAlignment.center,
  //   spacing: 8,
  //   runSpacing: 4,
  //   children: [
  //     _statusChip("Pending", pending, Colors.orange),
  //     _statusChip("In Progress", inProgress, Colors.blue),
  //     _statusChip("Completed", completed, Colors.green),
  //   ],
  // )

  //                 // Row(
  //                 //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //                 //   children: [
  //                 //     _statusChip("Pending", pending, Colors.orange),
  //                 //     _statusChip("In Progress", inProgress, Colors.blue),
  //                 //     _statusChip("Completed", completed, Colors.green),
  //                 //   ],
  //                 // ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ),
  //     );
  //   }

  Widget _taskCard({
    required int totalTasks,
    required int pending,
    required int inProgress,
    required int completed,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color.withOpacity(0.8), color]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.assignment, size: 50, color: color),
                      const SizedBox(height: 6),
                      Text(
                        "Tasks Overview",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Total: $totalTasks",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Divider(height: 1, thickness: 1),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _statusChip("Pending", pending, Colors.orange),
                          _statusChip("In Progress", inProgress, Colors.blue),
                          _statusChip("Completed", completed, Colors.green),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String label, int count, Color color) {
    return Chip(
      label: Text(
        "$label: $count",
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
    );
  }
}
class WavingHand extends StatefulWidget {
  const WavingHand({super.key});

  @override
  State<WavingHand> createState() => _WavingHandState();
}

class _WavingHandState extends State<WavingHand>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) {
        return Transform.rotate(
          angle: _controller.value * 0.4 - 0.2, // waving motion
          child: child,
        );
      },
      child: const Icon(
        Icons.waving_hand_rounded,
        color: Colors.yellow,
        size: 26,
      ),
    );
  }
}
