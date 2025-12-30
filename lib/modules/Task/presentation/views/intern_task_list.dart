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
/// SAFE TIMESTAMP GETTER
/// =========================
DateTime getSafeTime(Map<String, dynamic> data) {
  final keys = [
    'timestamp',     // forced entries
    'date',          // report date
    'start_date',    
    'completed_date',
    'updated_at',
  ];

  for (final key in keys) {
    final value = data[key];
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
  }

  // fallback so UI never crashes
  return DateTime.fromMillisecondsSinceEpoch(0);
}

/// =========================
/// BUILD FULL TIMELINE
/// =========================
Future<List<Map<String, dynamic>>> buildProgressTimeline(Map<String, dynamic> task) async {
  final List<Map<String, dynamic>> timeline = [];
  final taskId = task['task_id'];

  // Fetch reports
  final snapshot = await FirebaseFirestore.instance
      .collection('reports')
      .where('task_id', isEqualTo: taskId)
      .get();

  Timestamp? firstStart;

  for (final doc in snapshot.docs) {
    final data = doc.data();
    if (firstStart == null && data['start_date'] is Timestamp) {
      firstStart = data['start_date'];
    }

    // ensure timestamp exists for sorting
    if (!data.containsKey('timestamp')) {
      data['timestamp'] = data['date'] ?? data['start_date'] ?? task['updated_at'];
    }

    timeline.add(data);
  }

  // Add 0% entry from start
  if (firstStart != null) {
    timeline.insert(0, {
      'progress_percent': 0,
      'description': 'No description available',
      'timestamp': firstStart,
    });
  }

  // Force 100% if task completed
  final has100 = timeline.any((e) {
    final p = e['progress_percent'];
    final v = p is num ? p.toInt() : int.tryParse(p.toString()) ?? 0;
    return v == 100;
  });

  if (!has100 && task['status'] == 'Completed') {
    timeline.add({
      'progress_percent': 100,
      'description': 'Task completed',
      'timestamp': task['completed_date'] ?? task['updated_at'],
    });
  }

  // Sort by time
  timeline.sort((a, b) => getSafeTime(a).compareTo(getSafeTime(b)));

  return timeline;
}

/// =========================
/// SHOW PROGRESS POPUP
/// =========================
void showProgressPopup(BuildContext context, Map<String, dynamic> task) async {
  final timeline = await buildProgressTimeline(task);
  if (!context.mounted) return;

  DateTime? startTime = timeline.isNotEmpty ? getSafeTime(timeline.first) : null;
  DateTime? endTime = timeline.isNotEmpty ? getSafeTime(timeline.last) : null;

  String avgTime = "--";
  if (startTime != null && endTime != null) {
    final diff = endTime.difference(startTime);
    avgTime = "${diff.inHours} hr ${diff.inMinutes.remainder(60)} min";
  }

  // String dueDate = task['due_date'] is Timestamp
  //     ? DateFormat('dd/MM/yyyy hh:mm a').format((task['due_date'] as Timestamp).toDate())
  //     : "--";

  showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task['title'] ?? '',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text("Average Time: $avgTime"),
            const SizedBox(height: 2),
           // Text("Due Date: $dueDate"),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: timeline.length,
                itemBuilder: (context, index) {
                  final item = timeline[index];
                  final time = getSafeTime(item);
                  final progress = item['progress_percent'] is num
                      ? item['progress_percent'].toInt()
                      : int.tryParse(item['progress_percent'].toString()) ?? 0;
                  final formattedDate = DateFormat('dd/MM/yyyy hh:mm a').format(time);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("$formattedDate - $progress%",
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(item['description'] ?? 'No description available',
                          style: const TextStyle(color: Colors.black54)),
                      const SizedBox(height: 14),
                    ],
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
            )
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
