import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ParticularEmployeeTaskListScreen extends StatefulWidget {
  final String currentUserId;
  final String currentUserRole;

  const ParticularEmployeeTaskListScreen({
    super.key,
    required this.currentUserId,
    required this.currentUserRole,
  });

  @override
  State<ParticularEmployeeTaskListScreen> createState() =>
      _ParticularEmployeeTaskListScreenState();
}

class _ParticularEmployeeTaskListScreenState
    extends State<ParticularEmployeeTaskListScreen> {
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _filteredTasks = [];
  bool _isLoading = true;
  String _filterField = 'All';
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  final List<String> filterOptions = [
    'All',
    'High Priority',
    'Pending',
    'In Progress',
    'Completed',
  ];

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  // 🔹 Helper - Get user name
  Future<String> getUserName(DocumentReference? userRef) async {
    if (userRef == null) return 'N/A';
    try {
      final snap = await userRef.get();
      final data = snap.data() as Map<String, dynamic>?;
      if (data == null) return 'N/A';
      if (data.containsKey('emp_name')) return data['emp_name'];
      if (data.containsKey('intern_name')) return data['intern_name'];
      if (data.containsKey('user_name')) return data['user_name'];
      return 'N/A';
    } catch (e) {
      return 'N/A';
    }
  }

  // 🔹 Helper - Get department name
  Future<String> getDepartmentName(DocumentReference? deptRef) async {
    if (deptRef == null) return 'N/A';
    try {
      final snap = await deptRef.get();
      final data = snap.data() as Map<String, dynamic>?;
      return data?['dept_name'] ?? 'N/A';
    } catch (e) {
      return 'N/A';
    }
  }

  // 🔹 Fetch only tasks assigned to this user
  Future<void> fetchTasks() async {
    setState(() => _isLoading = true);
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('tasks').get();
      List<Map<String, dynamic>> taskList = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final id = doc.id;

        // Check if assigned_to matches this user
        final assignedTo = data['assigned_to'];
        String? assignedToId;
        if (assignedTo is DocumentReference) {
          assignedToId = assignedTo.id;
        } else if (assignedTo is String) {
          assignedToId = assignedTo;
        }

        if (assignedToId != widget.currentUserId) continue;

        final assignedByName = await getUserName(
          data['assigned_by'] as DocumentReference?,
        );
        final deptName = await getDepartmentName(
          data['department_id'] as DocumentReference?,
        );
        final startDate = (data['start_date'] as Timestamp?)?.toDate();
        final dueDate = (data['due_date'] as Timestamp?)?.toDate();
        final completedDate = (data['completed_date'] as Timestamp?)?.toDate();

        taskList.add({
          'task_id': id,
          'title': data['title'] ?? '',
          'description': data['description'] ?? '',
          'priority': data['priority'] ?? '',
          'status': data['status'] ?? '',
          'progress_percent': data['progress_percent'] ?? '0',
          'start_date': startDate,
          'due_date': dueDate,
          'completed_date': completedDate,
          'assigned_by_name': assignedByName,
          'department_name': deptName,
        });
      }

      setState(() {
        _tasks = taskList;
        _filteredTasks = List.from(_tasks);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching tasks: $e");
      setState(() => _isLoading = false);
    }
  }

  /// =========================
  /// UPDATE TASK PROGRESS
  /// =========================
  Future<void> updateTaskProgress({
    required String taskId,
    required int progress,
    String description = '',
  }) async {
    final now = FieldValue.serverTimestamp();

    debugPrint("🔹 Updating Task: $taskId with progress: $progress%");

    // 🔹 Update task document
    await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
      'progress_percent': progress, // numeric
      'updated_at': now,
      if (progress == 100) ...{'status': 'Completed', 'completed_date': now},
    });

    debugPrint("✅ Task document updated");

    // 🔹 Create report entry
    await FirebaseFirestore.instance.collection('reports').add({
      'task_id': taskId,
      'progress_percent': progress, // numeric
      'description': progress == 100 ? 'Task completed' : description,
      'timestamp': now, // single source of truth
    });

    debugPrint("✅ Report added for task $taskId with progress $progress%");
  }

  /// =========================
  /// SAFE TIMESTAMP FETCH
  /// =========================
  DateTime getSafeTime(Map<String, dynamic> data) {
    if (data['timestamp'] is Timestamp)
      return (data['timestamp'] as Timestamp).toDate();
    if (data['created_at'] is Timestamp)
      return (data['created_at'] as Timestamp).toDate();
    if (data['updated_at'] is Timestamp)
      return (data['updated_at'] as Timestamp).toDate();
    if (data['date'] is Timestamp) return (data['date'] as Timestamp).toDate();

    debugPrint("⚠️ No valid timestamp found, returning DateTime.now()");
    return DateTime.now();
  }

  /// =========================
  /// FETCH REPORTS TIMELINE
  /// =========================
  Future<List<Map<String, dynamic>>> fetchReportsTimeline(
    Map<String, dynamic> task,
  ) async {
    try {
      final taskId = task['task_id'];
      final snapshot =
          await FirebaseFirestore.instance
              .collection('reports')
              .where('task_id', isEqualTo: taskId)
              .get();

      final reports = snapshot.docs.map((e) => e.data()).toList();

      debugPrint("🔹 Fetched ${reports.length} reports for task $taskId");

      // 🔹 Add latest task progress if not already in reports
      final taskProgress = task['progress_percent'];
      if (taskProgress != null) {
        final progress =
            taskProgress is num
                ? taskProgress.toDouble()
                : double.tryParse(taskProgress.toString()) ?? 0;

        // Check if 100% report exists
        final has100Report = reports.any((r) {
          final rProgress = r['progress_percent'];
          final val =
              rProgress is num
                  ? rProgress.toDouble()
                  : double.tryParse(rProgress?.toString() ?? '0') ?? 0;
          return val == progress && progress == 100;
        });

        if (progress == 100 && !has100Report) {
          reports.add({
            'progress_percent': 100,
            'description': 'Task completed',
            'timestamp':
                task['completed_date'] ?? task['updated_at'] ?? Timestamp.now(),
          });
        }
      }

      // Sort by timestamp
      reports.sort((a, b) {
        final at = getSafeTime(a);
        final bt = getSafeTime(b);
        return at.compareTo(bt);
      });

      // Debug print elapsed
      DateTime? prevTime;
      for (var i = 0; i < reports.length; i++) {
        final report = reports[i];
        final currentTime = getSafeTime(report);

        String elapsedTime = "0 min";
        if (prevTime != null) {
          final diff = currentTime.difference(prevTime);
          final h = diff.inHours;
          final m = diff.inMinutes.remainder(60);
          elapsedTime =
              diff.inMinutes > 0 ? "${h > 0 ? "$h hr " : ""}$m min" : "0 min";
        }

        final raw = report['progress_percent'];
        final progress =
            raw is num
                ? raw.toDouble()
                : double.tryParse(raw?.toString() ?? '0') ?? 0;

        debugPrint(
          "Report ${i + 1}: Progress = ${progress.toInt()}%, Timestamp = $currentTime, Elapsed since prev = $elapsedTime",
        );

        prevTime = currentTime;
      }

      return reports;
    } catch (e) {
      debugPrint("❌ Fetch error: $e");
      return [];
    }
  }

  /// =========================
  /// SHOW PROGRESS POPUP
  /// =========================
  void showProgressPopup(
    BuildContext context,
    Map<String, dynamic> task,
  ) async {
    final reports = await fetchReportsTimeline(task);
    if (!context.mounted) return;

    DateTime? startTime =
        reports.isNotEmpty ? getSafeTime(reports.first) : null;
    DateTime? endTime = reports.isNotEmpty ? getSafeTime(reports.last) : null;

    Duration? totalDuration =
        (startTime != null && endTime != null)
            ? endTime.difference(startTime)
            : null;

    String avgTime =
        totalDuration != null
            ? "${totalDuration.inHours} hr ${totalDuration.inMinutes.remainder(60)} min"
            : "--";

    debugPrint("🔹 Total Duration: $avgTime");

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              constraints: const BoxConstraints(maxHeight: 450),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task['title'] ?? 'Untitled',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    task['description'] ?? '',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 10),
                  Text("Average Time: $avgTime"),
                  const Divider(),
                  Expanded(
                    child:
                        reports.isEmpty
                            ? const Center(
                              child: Text("No progress updates found"),
                            )
                            : ListView.builder(
                              itemCount: reports.length,
                              itemBuilder: (context, index) {
                                final report = reports[index];
                                final DateTime currentTime = getSafeTime(
                                  report,
                                );

                                DateTime? prevTime;
                                if (index > 0)
                                  prevTime = getSafeTime(reports[index - 1]);
                                else if (task['start_date'] is Timestamp)
                                  prevTime =
                                      (task['start_date'] as Timestamp)
                                          .toDate();

                                String elapsedTime = "0 min";
                                if (prevTime != null) {
                                  final diff = currentTime.difference(prevTime);
                                  final h = diff.inHours;
                                  final m = diff.inMinutes.remainder(60);
                                  elapsedTime =
                                      diff.inMinutes > 0
                                          ? "${h > 0 ? "$h hr " : ""}$m min"
                                          : "0 min";
                                }

                                final raw = report['progress_percent'];
                                final progress =
                                    raw is num
                                        ? raw.toDouble()
                                        : double.tryParse(
                                              raw?.toString() ?? '0',
                                            ) ??
                                            0;

                                final formattedDate = DateFormat(
                                  'dd/MM/yyyy hh:mm a',
                                ).format(currentTime);

                                return Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                    horizontal: 6,
                                  ),
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.timeline,
                                      color:
                                          progress >= 100
                                              ? Colors.green
                                              : Colors.blueAccent,
                                    ),
                                    title: Text(
                                      "$formattedDate — ${progress.toInt()}% (after $elapsedTime)",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      report['description'] ??
                                          'No description available',
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Close"),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // 🔹 Filter
  void applyFilter() {
    if (_filterField == 'All') {
      _filteredTasks = List.from(_tasks);
    } else if (_filterField == 'High Priority') {
      _filteredTasks = _tasks.where((t) => t['priority'] == 'High').toList();
    } else {
      _filteredTasks =
          _tasks.where((t) => t['status'] == _filterField).toList();
    }
    setState(() {});
  }

  // 🔹 Format avg time from start/completed dates
  String formatAvgTimeFromDates(
    dynamic start,
    dynamic completed,
    String status,
  ) {
    if (status != 'Completed') return "--";
    if (start == null || completed == null) return "--";

    DateTime? s = start is Timestamp ? start.toDate() : start;
    DateTime? e = completed is Timestamp ? completed.toDate() : completed;
    if (s == null || e == null) return "--";

    final diff = e.difference(s);
    final h = diff.inHours;
    final m = diff.inMinutes.remainder(60);
    return h > 0 ? "$h hr ${m > 0 ? '$m min' : ''}" : "$m min";
  }

  // 🔹 Status Chip
  Widget _statusChip(String status) {
    Color color;
    switch (status) {
      case 'Pending':
        color = Colors.orange;
        break;
      case 'In Progress':
        color = Colors.blue;
        break;
      case 'Completed':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

 Widget _buildTaskTable() {
  final dateFormat = DateFormat('dd-MM-yyyy');

  return ScrollConfiguration(
    behavior: ScrollConfiguration.of(context).copyWith(
      dragDevices: {
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.touch,
      },
      scrollbars: true,
    ),
    child: Scrollbar(
      controller: _verticalController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _horizontalController,
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          controller: _verticalController,
          scrollDirection: Axis.vertical,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(const Color(0xFF076AB1)),
            headingTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            columns: const [
              DataColumn(label: Text("Title")),
              DataColumn(label: Text("Description")),
              DataColumn(label: Text("Assigned By")),
            
              DataColumn(label: Text("Department")),
              DataColumn(label: Text("Priority")),
              DataColumn(label: Text("Status")),
              DataColumn(label: Text("Progress %")),
              DataColumn(label: Text("Avg Time")),
              DataColumn(label: Text("Due Date")),
              DataColumn(label: Text("Start Date")),
              DataColumn(label: Text("Completed Date")),
            ],
            rows: _filteredTasks.map((task) {
              return DataRow(
                cells: [
                  DataCell(Text(task['title'] ?? '')),
                  DataCell(Text(task['description'] ?? '')),
                  DataCell(Text(task['assigned_by_name'] ?? 'N/A')),
                 
                  DataCell(Text(task['department_name'] ?? 'N/A')),
                  DataCell(Text(task['priority'] ?? '')),
                  DataCell(_statusChip(task['status'] ?? '')),
                  DataCell(
                    GestureDetector(
                      onTap: () => showProgressPopup(context, task),
                      child: Text(
                        "${task['progress_percent']}% (click)",
                        style: const TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      formatAvgTimeFromDates(
                        task['start_date'],
                        task['completed_date'],
                        task['status'],
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      task['due_date'] != null
                          ? dateFormat.format(task['due_date'])
                          : '--',
                    ),
                  ),
                  DataCell(
                    Text(
                      task['start_date'] != null
                          ? dateFormat.format(task['start_date'])
                          : '--',
                    ),
                  ),
                  DataCell(
                    Text(
                      task['completed_date'] != null
                          ? dateFormat.format(task['completed_date'])
                          : (task['due_date'] != null
                              ? dateFormat.format(task['due_date'])
                              : '--'),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 🔹 Gradient AppBar
          Container(
            height: kToolbarHeight + 10,
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
            ),
            child: const SafeArea(
              child: Row(
                children: [
                  BackButton(color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    backgroundImage: AssetImage('assets/logo.png'),
                  ),
                  SizedBox(width: 8),
                ],
              ),
            ),
          ),

          // 🔹 Filter & Refresh
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: fetchTasks,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Refresh"),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _filterField,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _filterField = value);
                      applyFilter();
                    }
                  },
                  items:
                      filterOptions
                          .map(
                            (f) => DropdownMenuItem(value: f, child: Text(f)),
                          )
                          .toList(),
                ),
              ],
            ),
          ),

          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child:
                          _filteredTasks.isEmpty
                              ? const Center(
                                child: Text("No tasks assigned to you."),
                              )
                              : _buildTaskTable(),
                    ),
          ),
        ],
      ),
    );
  }
}
