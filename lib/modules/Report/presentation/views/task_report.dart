// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter/material.dart';

// class EmployeeTaskReportScreen extends StatefulWidget {
//   const EmployeeTaskReportScreen({super.key});

//   @override
//   State<EmployeeTaskReportScreen> createState() =>
//       _EmployeeTaskReportScreenState();
// }

// class _EmployeeTaskReportScreenState extends State<EmployeeTaskReportScreen> {
//   String? selectedEmployee;
//   List<Map<String, dynamic>> employees = [];
//   Map<String, int> taskCount = {};
//   Map<String, double> completionRate = {};
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     fetchEmployees();
//     fetchTaskReport();
//   }

//   /// ✅ Fetch all employees safely
//   Future<void> fetchEmployees() async {
//     final snapshot = await FirebaseFirestore.instance.collection('users').get();

//     setState(() {
//       employees = snapshot.docs.map((doc) {
//         final data = doc.data();
//         final name = data['user_name'] ??
//             data['emp_name'] ??
//             data['name'] ??
//             'Unknown User';
//         return {'id': doc.id, 'name': name};
//       }).toList();
//     });
//   }

//   /// ✅ Fetch tasks & compute report safely
//   Future<void> fetchTaskReport({String? filterEmployeeId}) async {
//     setState(() => isLoading = true);

//     final snapshot = await FirebaseFirestore.instance.collection('tasks').get();

//     Map<String, int> total = {};
//     Map<String, int> completed = {};

//     for (var doc in snapshot.docs) {
//       final data = doc.data();

//       final assignedToRef = data['assigned_to'] as DocumentReference?;
//       if (assignedToRef == null) continue;

//       final userId = assignedToRef.id;
//       if (filterEmployeeId != null && userId != filterEmployeeId) continue;

//       total[userId] = (total[userId] ?? 0) + 1;
//       if (data['status'] == 'Completed') {
//         completed[userId] = (completed[userId] ?? 0) + 1;
//       }
//     }

//     Map<String, int> mappedCount = {};
//     Map<String, double> mappedCompletion = {};

//     for (var entry in total.entries) {
//       final userSnap =
//           await FirebaseFirestore.instance.collection('users').doc(entry.key).get();

//       if (!userSnap.exists) continue;

//       final userData = userSnap.data() ?? {};
//       final name = userData['user_name'] ??
//           userData['emp_name'] ??
//           userData['name'] ??
//           'Unknown User';

//       mappedCount[name] = entry.value;
//       mappedCompletion[name] =
//           ((completed[entry.key] ?? 0) / entry.value) * 100;
//     }

//     setState(() {
//       taskCount = mappedCount;
//       completionRate = mappedCompletion;
//       isLoading = false;
//     });
//   }

//   /// ✅ Filter Dialog
//   void showFilterDialog() {
//     showDialog(
//       context: context,
//       builder: (ctx) {
//         return AlertDialog(
//           title: const Text("Filter by Employee"),
//           content: DropdownButtonFormField<String>(
//             value: selectedEmployee,
//             items: employees
//                 .map(
//                   (e) => DropdownMenuItem<String>(
//                     value: e['id'],
//                     child: Text(e['name']),
//                   ),
//                 )
//                 .toList(),
//             onChanged: (val) => setState(() => selectedEmployee = val),
//             decoration: const InputDecoration(labelText: 'Select Employee'),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(ctx);
//                 fetchTaskReport(filterEmployeeId: selectedEmployee);
//               },
//               child: const Text("Apply"),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final barData = taskCount.entries.toList();
//     final pieData = completionRate.entries.toList();

//     return Scaffold(
//       appBar: const GradientAppBar(title: ""),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   // 🔹 Buttons Row
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.end,
//                     children: [
//                       ElevatedButton.icon(
//                         onPressed: showFilterDialog,
//                         icon: const Icon(Icons.filter_alt_rounded),
//                         label: const Text("Filter"),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.blueAccent,
//                           foregroundColor: Colors.white,
//                         ),
//                       ),
//                       const SizedBox(width: 10),
//                       ElevatedButton.icon(
//                         onPressed: () {
//                           setState(() => selectedEmployee = null);
//                           fetchTaskReport();
//                         },
//                         icon: const Icon(Icons.refresh_rounded),
//                         label: const Text("Refresh"),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.green,
//                           foregroundColor: Colors.white,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 30),

//                   const Text(
//                     "📊 Task Count per Employee",
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 20),

//                   // --- Bar Chart ---
//                   if (barData.isEmpty)
//                     const Text("No data available")
//                   else
//                     SizedBox(
//                       height: 300,
//                       child: BarChart(
//                         BarChartData(
//                           alignment: BarChartAlignment.spaceAround,
//                           borderData: FlBorderData(show: false),
//                           titlesData: FlTitlesData(
//                             leftTitles: const AxisTitles(
//                               sideTitles: SideTitles(showTitles: true),
//                             ),
//                             bottomTitles: AxisTitles(
//                               sideTitles: SideTitles(
//                                 showTitles: true,
//                                 getTitlesWidget: (double value, meta) {
//                                   if (value.toInt() < barData.length) {
//                                     return Padding(
//                                       padding: const EdgeInsets.only(top: 8.0),
//                                       child: Text(
//                                         barData[value.toInt()].key,
//                                         style: const TextStyle(fontSize: 10),
//                                       ),
//                                     );
//                                   }
//                                   return const Text('');
//                                 },
//                               ),
//                             ),
//                           ),
//                           barGroups: List.generate(
//                             barData.length,
//                             (i) => BarChartGroupData(
//                               x: i,
//                               barRods: [
//                                 BarChartRodData(
//                                   toY: barData[i].value.toDouble(),
//                                   color: Colors.blueAccent,
//                                   width: 18,
//                                   borderRadius: BorderRadius.circular(4),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),

//                   const SizedBox(height: 40),
//                   const Text(
//                     "🥧 Task Completion Rate (%)",
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 20),

//                   // --- Pie Chart ---
//                   if (pieData.isEmpty)
//                     const Text("No data available")
//                   else
//                     SizedBox(
//                       height: 300,
//                       child: PieChart(
//                         PieChartData(
//                           sectionsSpace: 4,
//                           centerSpaceRadius: 50,
//                           sections: pieData.map((entry) {
//                             final color = Colors.primaries[
//                                 pieData.indexOf(entry) %
//                                     Colors.primaries.length];
//                             return PieChartSectionData(
//                               color: color,
//                               value: entry.value,
//                               title:
//                                   "${entry.key}\n${entry.value.toStringAsFixed(1)}%",
//                               radius: 80,
//                               titleStyle: const TextStyle(
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.white,
//                               ),
//                             );
//                           }).toList(),
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//     );
//   }
// }

// class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
//   final String title;
//   final bool showBack;
//   final VoidCallback? onBackPressed;

//   const GradientAppBar({
//     super.key,
//     required this.title,
//     this.showBack = true,
//     this.onBackPressed,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: kToolbarHeight + 12,
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             Color(0xFF34D0C6),
//             Color(0xFF22A4E0),
//             Color(0xFF1565C0),
//           ],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black26,
//             blurRadius: 6,
//             offset: Offset(0, 3),
//           ),
//         ],
//         borderRadius: BorderRadius.vertical(
//           bottom: Radius.circular(16),
//         ),
//       ),
//       child: SafeArea(
//         bottom: false,
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 12),
//           child: Row(
//             children: [
//               if (showBack)
//                 IconButton(
//                   icon: const Icon(Icons.arrow_back_ios_new_rounded,
//                       color: Colors.white),
//                   onPressed: onBackPressed ?? () => Navigator.pop(context),
//                 ),
//               if (showBack) const SizedBox(width: 6),
//               Expanded(
//                 child: Text(
//                   title,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 20,
//                     fontWeight: FontWeight.w600,
//                     letterSpacing: 0.5,
//                   ),
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//               Container(
//                 height: 40,
//                 width: 40,
//                 decoration: const BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: Colors.white,
//                   image: DecorationImage(
//                     image: AssetImage('assets/logo.png'),
//                     fit: BoxFit.cover,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   Size get preferredSize => const Size.fromHeight(kToolbarHeight + 12);
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// ----------------------
/// USERS TAB SCREEN
/// ----------------------
class EmployeeInternScreen extends StatefulWidget {
  const EmployeeInternScreen({super.key});

  @override
  State<EmployeeInternScreen> createState() => _EmployeeInternScreenState();
}

class _EmployeeInternScreenState extends State<EmployeeInternScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> employees = [];
  List<Map<String, dynamic>> interns = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    setState(() => isLoading = true);
    final snapshot = await FirebaseFirestore.instance.collection('users').get();

    List<Map<String, dynamic>> emp = [];
    List<Map<String, dynamic>> intern = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final role = (data['role'] ?? 'employee').toString().toLowerCase();
      final name = data['user_name'] ?? data['emp_name'] ?? 'Unknown';
      final designation = data['emp_designation'] ?? 'Staff';
      final id = doc.id;

      final user = {'id': id, 'name': name, 'designation': designation};

      if (role == 'intern') {
        intern.add(user);
      } else {
        emp.add(user);
      }
    }

    setState(() {
      employees = emp;
      interns = intern;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: AssetImage('assets/logo.png'),
            ),
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF34D0C6), Color(0xFF22A4E0), Color(0xFF1565C0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: "Employees"),
                    Tab(text: "Interns"),
                  ],
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.blue,
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      userListTab(employees),
                      userListTab(interns),
                    ],
                  ),
                )
              ],
            ),
    );
  }

  Widget userListTab(List<Map<String, dynamic>> users) {
    if (users.isEmpty) return const Center(child: Text("No data found"));

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final color = Colors.primaries[index % Colors.primaries.length];

        return Hero(
          tag: user['id'],
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: color.shade200,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.shade400.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              title: Text(user['name'],
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black)),
              subtitle: Text(user['designation'], style: const TextStyle(color: Colors.black87)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.black54),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EmployeeTaskReportScreen(employeeId: user['id'], employeeName: user['name']),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}


class EmployeeTaskReportScreen extends StatefulWidget {
  final String employeeId;
  final String employeeName;
  const EmployeeTaskReportScreen({super.key, required this.employeeId, required this.employeeName});

  @override
  State<EmployeeTaskReportScreen> createState() => _EmployeeTaskReportScreenState();
}

class _EmployeeTaskReportScreenState extends State<EmployeeTaskReportScreen> {
  Map<String, int> taskStatusCount = {
    "Completed": 0,
    "In Progress": 0,
    "Pending": 0,
  };
  List<Map<String, dynamic>> taskList = [];
  bool isLoading = true;
  double progress = 0.0;

  @override
  void initState() {
    super.initState();
    fetchTaskReport();
  }

  /// =========================
  /// SAFE INT PARSER
  /// =========================
  int safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// =========================
  /// SAFE TIMESTAMP GETTER
  /// =========================
  DateTime getSafeTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<void> fetchTaskReport() async {
    setState(() => isLoading = true);
    final snapshot = await FirebaseFirestore.instance.collection('tasks').get();

    int completed = 0;
    int inProgress = 0;
    int pending = 0;
    List<Map<String, dynamic>> tasks = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final assignedToRef = data['assigned_to'] as DocumentReference?;
      if (assignedToRef == null || assignedToRef.id != widget.employeeId) continue;

      final status = data['status'] ?? 'Pending';
      if (status == 'Completed') completed++;
      else if (status == 'In Progress') inProgress++;
      else pending++;

      final startDate = getSafeTime(data['start_date']);
      final dueDate = getSafeTime(data['due_date']);
      final completedDate = getSafeTime(data['completed_date']);
      final estimatedHours = safeInt(data['estimated_hours'] ?? data['estimatedHours']);

      // Build timeline from reports collection
      final reportsSnapshot = await FirebaseFirestore.instance
          .collection('reports')
          .where('task_id', isEqualTo: doc.id)
          .get();

      List<Map<String, dynamic>> timeline = [];
      for (var r in reportsSnapshot.docs) {
        final rep = r.data();
        timeline.add({
          'description': rep['description'] ?? 'No description',
          'progress_percent': safeInt(rep['progress_percent']),
          'timestamp': getSafeTime(rep['timestamp'] ?? rep['date'] ?? rep['start_date'])
        });
      }

      // Add start and completion if missing
      if (timeline.isEmpty) {
        timeline.add({
          'description': 'Task started',
          'progress_percent': 0,
          'timestamp': startDate
        });
      }
      if (status == 'Completed' && !timeline.any((e) => safeInt(e['progress_percent']) == 100)) {
        timeline.add({
          'description': 'Task completed',
          'progress_percent': 100,
          'timestamp': completedDate
        });
      }

      timeline.sort((a, b) => getSafeTime(a['timestamp']).compareTo(getSafeTime(b['timestamp'])));

      tasks.add({
        'title': data['title'] ?? 'Unnamed Task',
        'status': status,
        'startDate': startDate,
        'dueDate': dueDate,
        'completedDate': completedDate,
        'estimatedHours': estimatedHours,
        'timeline': timeline,
      });
    }

    final total = completed + inProgress + pending;
    final prog = total == 0 ? 0.0 : completed / total;

    setState(() {
      taskStatusCount = {
        "Completed": completed,
        "In Progress": inProgress,
        "Pending": pending,
      };
      taskList = tasks;
      progress = prog;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final barData = taskStatusCount.entries.toList();

    return Scaffold(
      appBar: GradientAppBar(title: "${widget.employeeName} Tasks"),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Summary Cards ---
                  ...taskStatusCount.entries.map((entry) {
                    Color color;
                    if (entry.key == "Completed") color = Colors.green.shade300;
                    else if (entry.key == "In Progress") color = Colors.orange.shade300;
                    else color = Colors.red.shade300;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.5),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(entry.value.toString(),
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 20),
                  const Text(
                    "Overall Task Progress",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: LinearProgressIndicator(
                      minHeight: 20,
                      value: progress,
                      color: Colors.blueAccent,
                      backgroundColor: Colors.grey.shade300,
                    ),
                  ),
                  const SizedBox(height: 30),

                  const Text(
                    "Task Distribution Chart",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 250,
                    child: PieChart(
                      PieChartData(
                        centerSpaceRadius: 50,
                        sectionsSpace: 4,
                        sections: barData.map((entry) {
                          Color color;
                          if (entry.key == "Completed") color = Colors.green;
                          else if (entry.key == "In Progress") color = Colors.orange;
                          else color = Colors.red;

                          return PieChartSectionData(
                            color: color,
                            value: entry.value.toDouble(),
                            title: "${entry.key}\n${entry.value}",
                            radius: 80,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                  const Text(
                    "Task Details",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // --- Task Details Cards ---
                  ListView.builder(
                    itemCount: taskList.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final task = taskList[index];
                      Color color;
                      if (task['status'] == "Completed") color = Colors.green.shade200;
                      else if (task['status'] == "In Progress") color = Colors.orange.shade200;
                      else color = Colors.red.shade200;

                      // Calculate total duration
                      DateTime start = task['startDate'];
                      DateTime end = task['status'] == 'Completed'
                          ? task['completedDate']
                          : DateTime.now();
                      final duration = end.difference(start);
                      final totalTime =
                          "${duration.inHours} hr ${duration.inMinutes.remainder(60)} min";

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.5),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(task['title'],
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Status: ${task['status']}"),
                                Text("Total Time: $totalTime"),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                                "Start: ${DateFormat('dd/MM/yyyy').format(task['startDate'])} | Due: ${DateFormat('dd/MM/yyyy').format(task['dueDate'])}"),
                            const SizedBox(height: 8),

                            // --- Inline Timeline ---
                            Row(
                              children: task['timeline'].map<Widget>((step) {
                                int progressPercent = safeInt(step['progress_percent']);
                                return Expanded(
                                  child: Column(
                                    children: [
                                      Container(
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: progressPercent == 100
                                              ? Colors.green
                                              : progressPercent >= 50
                                                  ? Colors.orange
                                                  : Colors.red,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text("$progressPercent%",
                                          style: const TextStyle(fontSize: 10)),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 8),

                            // --- Overall Progress Bar ---
                            LinearProgressIndicator(
                              value: task['status'] == "Completed"
                                  ? 1
                                  : task['status'] == "In Progress"
                                      ? 0.5
                                      : 0.0,
                              color: Colors.blueAccent,
                              backgroundColor: Colors.grey.shade300,
                              minHeight: 10,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}

/// Gradient AppBar
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final VoidCallback? onBackPressed;

  const GradientAppBar({
    super.key,
    required this.title,
    this.showBack = true,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: kToolbarHeight + 12,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF34D0C6),
            Color(0xFF22A4E0),
            Color(0xFF1565C0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              if (showBack)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white),
                  onPressed: onBackPressed ?? () => Navigator.pop(context),
                ),
              if (showBack) const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                height: 40,
                width: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  image: DecorationImage(
                    image: AssetImage('assets/logo.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 12);
}
