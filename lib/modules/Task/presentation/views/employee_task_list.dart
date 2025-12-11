
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EmployeeTaskListScreen extends StatefulWidget {
  final String currentUserId;
  final String currentUserRole;

  const EmployeeTaskListScreen({
    super.key,
    required this.currentUserId,
    required this.currentUserRole,
  });

  @override
  State<EmployeeTaskListScreen> createState() => _EmployeeTaskListScreenState();
}

class _EmployeeTaskListScreenState extends State<EmployeeTaskListScreen> {
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _filteredTasks = [];
  bool _isLoading = true;
  String? _editingTaskId;
  String _filterField = 'All';

  final Map<String, TextEditingController> _titleCtrls = {};
  final Map<String, TextEditingController> _descCtrls = {};
  final Map<String, TextEditingController> _priorityCtrls = {};
  final Map<String, TextEditingController> _statusCtrls = {};

  final Map<String, DateTime?> _startDates = {};
  final Map<String, DateTime?> _dueDates = {};
  final Map<String, DateTime?> _completedDates = {};

  final ScrollController _horizontalController = ScrollController();
final ScrollController _verticalController = ScrollController();

  final List<String> filterOptions = [
    'All',
    'High Priority',
    'Pending',
    'In Progress',
    'Completed'
  ];

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  // 🔹 Helper - Get user name from reference
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

  // 🔹 Fetch Tasks
  Future<void> fetchTasks() async {
    setState(() {
      _isLoading = true;
      _filterField = 'All';
    });

    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('tasks').get();
      List<Map<String, dynamic>> taskList = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final id = doc.id;

        final assignedByName =
            await getUserName(data['assigned_by'] as DocumentReference?);
        final assignedToName =
            await getUserName(data['assigned_to'] as DocumentReference?);
        final deptName =
            await getDepartmentName(data['department_id'] as DocumentReference?);

        _titleCtrls[id] = TextEditingController(text: data['title'] ?? '');
        _descCtrls[id] =
            TextEditingController(text: data['description'] ?? '');
        _priorityCtrls[id] =
            TextEditingController(text: data['priority'] ?? '');
        _statusCtrls[id] = TextEditingController(text: data['status'] ?? '');
        _startDates[id] = data['start_date'] != null
            ? (data['start_date'] as Timestamp).toDate()
            : null;
        _dueDates[id] = data['due_date'] != null
            ? (data['due_date'] as Timestamp).toDate()
            : null;
        _completedDates[id] = data['completed_date'] != null
            ? (data['completed_date'] as Timestamp).toDate()
            : null;

        taskList.add({
          'task_id': id,
          'title': data['title'] ?? '',
          'description': data['description'] ?? '',
          'priority': data['priority'] ?? '',
          'status': data['status'] ?? '',
          'progress_percent': data['progress_percent'] ?? '0',
          'start_date': _startDates[id],
          'due_date': _dueDates[id],
          'completed_date': _completedDates[id],
          'assigned_by_name': assignedByName,
          'assigned_to_name': assignedToName,
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

  // 🔹 Fetch reports timeline
  Future<List<Map<String, dynamic>>> fetchReportsTimeline(String taskId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('reports')
          .where('task_id', isEqualTo: taskId)
          .get();

      final reports = snapshot.docs.map((doc) => doc.data()).toList();
      reports.sort((a, b) {
        final at = (a['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0);
        final bt = (b['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0);
        return at.compareTo(bt);
      });
      return reports;
    } catch (e) {
      debugPrint("Error fetching reports: $e");
      return [];
    }
  }

  // 🔹 Show Progress Popup
  void showProgressPopup(Map<String, dynamic> task) async {
    final reports = await fetchReportsTimeline(task['task_id']);
    if (!mounted) return;

    DateTime? startTime =
        (reports.isNotEmpty ? (reports.first['timestamp'] as Timestamp?)?.toDate() : null);
    DateTime? endTime =
        (reports.isNotEmpty ? (reports.last['timestamp'] as Timestamp?)?.toDate() : null);
    Duration? totalDuration =
        (startTime != null && endTime != null) ? endTime.difference(startTime) : null;

    String avgTime = totalDuration != null
        ? "${totalDuration.inHours} hr ${totalDuration.inMinutes.remainder(60)} min"
        : "--";

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxHeight: 450),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(task['title'] ?? 'Untitled',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
              const SizedBox(height: 6),
              Text(task['description'] ?? '',
                  style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 10),
              Text("Average Time: $avgTime"),
              const Divider(),
              Expanded(
                child: reports.isEmpty
                    ? const Center(child: Text("No progress updates found"))
                    : ListView.builder(
  itemCount: reports.length,
  itemBuilder: (context, index) {
    final report = reports[index];

    // ✅ Extract timestamp (same as before)
   DateTime? currentTime;

// ✅ Handle multiple possible timestamp field names
if (report['timestamp'] is Timestamp) {
  currentTime = (report['timestamp'] as Timestamp).toDate();
} else if (report['created_at'] is Timestamp) {
  currentTime = (report['created_at'] as Timestamp).toDate();
} else if (report['date'] is Timestamp) {
  currentTime = (report['date'] as Timestamp).toDate();
} else if (report['updated_at'] is Timestamp) {
  currentTime = (report['updated_at'] as Timestamp).toDate();
} else {
  currentTime = DateTime.now(); // fallback
}


    // ✅ Previous report timestamp (for elapsed time)
    DateTime? prevTime;
    if (index > 0) {
      final prevReport = reports[index - 1];
      if (prevReport['timestamp'] is Timestamp) {
        prevTime = (prevReport['timestamp'] as Timestamp).toDate();
      } else if (prevReport['timestamp'] is DateTime) {
        prevTime = prevReport['timestamp'] as DateTime;
      } else if (prevReport.containsKey('created_at') && prevReport['created_at'] is Timestamp) {
        prevTime = (prevReport['created_at'] as Timestamp).toDate();
      }
    }

    // ✅ Fallback to task start time if first report
    if (index == 0 && task['start_date'] != null) {
      prevTime = task['start_date'];
    }

    // ✅ Format current timestamp
    final formattedDate = DateFormat('dd/MM/yyyy hh:mm a').format(currentTime);

    // ✅ Progress % conversion
    final progressRaw = report['progress_percent'];
    final progress = progressRaw is num
        ? progressRaw.toDouble()
        : num.tryParse(progressRaw?.toString() ?? '0')?.toDouble() ?? 0.0;

    // ✅ Description
    final desc = report['description'] ?? '';

    // ✅ Compute elapsed time between this and previous progress
    String elapsedTime = "--";
    if (prevTime != null) {
      final diff = currentTime.difference(prevTime);
      final h = diff.inHours;
      final m = diff.inMinutes.remainder(60);
      elapsedTime = h > 0 ? "$h hr ${m > 0 ? '$m min' : ''}" : "$m min";
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      child: ListTile(
        leading: Icon(
          Icons.timeline,
          color: progress >= 100 ? Colors.green : Colors.blueAccent,
        ),
        title: Text(
          "$formattedDate — ${progress.toStringAsFixed(0)}% (after $elapsedTime)",
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: desc.isNotEmpty
            ? Text(desc)
            : const Text("No description available"),
      ),
    );
  },
)
              ),


                         
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close")),
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

  // 🔹 Duration formatting
 String formatAvgTimeFromDates(dynamic start, dynamic completed, String status) {
  if (status != 'Completed') return "--"; // Only show for completed tasks
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
          color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
      child: Text(status,
          style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }

  // 🔹 Task Table
  Widget _buildTaskTable() {
    final dateFormat = DateFormat('dd-MM-yyyy');
    final isAdmin =
        widget.currentUserRole == 'admin' || widget.currentUserRole == 'super_admin';

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
          headingTextStyle:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          columns: const [
            DataColumn(label: Text("Title")),
            DataColumn(label: Text("Description")),
            DataColumn(label: Text("Assigned By")),
            DataColumn(label: Text("Assigned To")),
            DataColumn(label: Text("Department")),
            DataColumn(label: Text("Priority")),
            DataColumn(label: Text("Status")),
            DataColumn(label: Text("Progress %")),
            DataColumn(label: Text("Avg Time")),
            DataColumn(label: Text("Start Date")),
            DataColumn(label: Text("Due / Completed Date")),
            DataColumn(label: Text("Actions")),
          ],
          rows: _filteredTasks.map((task) {
            final id = task['task_id'];
            final isEditing = _editingTaskId == id;
      
            return DataRow(cells: [
              DataCell(isEditing
                  ? TextField(controller: _titleCtrls[id])
                  : Text(task['title'] ?? '')),
              DataCell(Text(task['description'] ?? '')),
              DataCell(Text(task['assigned_by_name'] ?? 'N/A')),
              DataCell(Text(task['assigned_to_name'] ?? 'N/A')),
              DataCell(Text(task['department_name'] ?? 'N/A')),
              DataCell(Text(task['priority'] ?? '')),
              DataCell(_statusChip(task['status'] ?? 'Unknown')),
              DataCell(
                GestureDetector(
                  onTap: () => showProgressPopup(task),
                  child: Text(
                    "${task['progress_percent']}% (click)",
                    style: const TextStyle(
                        color: Colors.blueAccent, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
             DataCell(Text(formatAvgTimeFromDates(
      task['start_date'], task['completed_date'], task['status']))),
      
              DataCell(Text(task['start_date'] != null
                  ? dateFormat.format(task['start_date'])
                  : '--')),
              DataCell(Text(task['completed_date'] != null
                  ? dateFormat.format(task['completed_date'])
                  : (task['due_date'] != null
                      ? dateFormat.format(task['due_date'])
                      : '--'))),
              DataCell(
                isAdmin
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isEditing) ...[
                            IconButton(
                                icon:
                                    const Icon(Icons.check, color: Colors.green),
                                onPressed: () => _saveTask(id)),
                            IconButton(
                                icon:
                                    const Icon(Icons.close, color: Colors.red),
                                onPressed: () =>
                                    setState(() => _editingTaskId = null)),
                          ] else ...[
                            IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () =>
                                    setState(() => _editingTaskId = id)),
                            IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteTask(id)),
                          ]
                        ],
                      )
                    : const Text('-'),
              ),
            ]);
          }).toList(),
        ),
        ),
      ),
    ),
    );
  }

  // 🔹 Save Task
  Future<void> _saveTask(String id) async {
    try {
      await FirebaseFirestore.instance.collection('tasks').doc(id).update({
        'title': _titleCtrls[id]?.text,
        'description': _descCtrls[id]?.text,
        'priority': _priorityCtrls[id]?.text,
        'status': _statusCtrls[id]?.text,
      });
      setState(() => _editingTaskId = null);
      fetchTasks();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // 🔹 Delete Task
  Future<void> _deleteTask(String id) async {
    await FirebaseFirestore.instance.collection('tasks').doc(id).delete();
    fetchTasks();
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
                colors: [Color(0xFF34D0C6), Color(0xFF22A4E0), Color(0xFF1565C0)],
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
                          fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  CircleAvatar(
                      backgroundColor: Colors.white,
                      backgroundImage: AssetImage('assets/logo.png')),
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
                  items: filterOptions
                      .map((f) =>
                          DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildTaskTable(),
                  ),
          ),
        ],
      ),
    );
  }
}
