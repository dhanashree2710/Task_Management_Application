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

  String _assignedByFilter = 'All';
  List<String> assignedByOptions = ['All'];

  String _assignedToFilter = 'All';
  List<String> assignedToOptions = ['All'];

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
    'Completed',
  ];
  final Map<String, TextEditingController> _progressCtrls = {};

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

        final assignedByName = await getUserName(
          data['assigned_by'] as DocumentReference?,
        );
        final assignedToName = await getUserName(
          data['assigned_to'] as DocumentReference?,
        );
        final deptName = await getDepartmentName(
          data['department_id'] as DocumentReference?,
        );

        _titleCtrls[id] = TextEditingController(text: data['title'] ?? '');
        _descCtrls[id] = TextEditingController(text: data['description'] ?? '');
        _priorityCtrls[id] = TextEditingController(
          text: data['priority'] ?? '',
        );
        _statusCtrls[id] = TextEditingController(text: data['status'] ?? '');
        _startDates[id] =
            data['start_date'] != null
                ? (data['start_date'] as Timestamp).toDate()
                : null;
        _dueDates[id] =
            data['due_date'] != null
                ? (data['due_date'] as Timestamp).toDate()
                : null;
        _completedDates[id] =
            data['completed_date'] != null
                ? (data['completed_date'] as Timestamp).toDate()
                : null;

        _progressCtrls[id] = TextEditingController(
          text: data['progress_percent']?.toString() ?? '0',
        );

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

        // 🔹 Assigned By names
        final assignedByNames =
            _tasks
                .map((t) => t['assigned_by_name'])
                .where((n) => n != null && n.toString().isNotEmpty)
                .toSet()
                .toList()
              ..sort();

        assignedByOptions = ['All', ...assignedByNames.cast<String>()];

        // 🔹 Assigned To names  ✅ REQUIRED
        final assignedToNames =
            _tasks
                .map((t) => t['assigned_to_name'])
                .where((n) => n != null && n.toString().isNotEmpty)
                .toSet()
                .toList()
              ..sort();

        assignedToOptions = ['All', ...assignedToNames.cast<String>()];

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


  void applyFilter() {
    _filteredTasks =
        _tasks.where((t) {
          // Main filter: Priority / Status
          bool matchesMainFilter = true;
          if (_filterField == 'High Priority') {
            matchesMainFilter = t['priority'] == 'High';
          } else if (_filterField != 'All') {
            matchesMainFilter = t['status'] == _filterField;
          }

          // Assigned By filter
          bool matchesAssignedBy = true;
          if (_assignedByFilter != 'All') {
            matchesAssignedBy = t['assigned_by_name'] == _assignedByFilter;
          }

          bool matchesAssignedTo = true;
          if (_assignedToFilter != 'All') {
            matchesAssignedTo = t['assigned_to_name'] == _assignedToFilter;
          }

          return matchesMainFilter && matchesAssignedBy && matchesAssignedTo;
        }).toList();

    setState(() {});
  }

  // 🔹 Duration formatting
  String formatAvgTimeFromDates(
    dynamic start,
    dynamic completed,
    String status,
  ) {
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
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  // 🔹 Task Table
  // 🔹 Task Table (All columns editable)
  Widget _buildTaskTable() {
    final dateFormat = DateFormat('dd-MM-yyyy');
    final isAdmin =
        widget.currentUserRole == 'admin' ||
        widget.currentUserRole == 'super_admin';

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
              headingRowColor: WidgetStateProperty.all(const Color(0xFF076AB1)),
              headingTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
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
                DataColumn(label: Text("Due Date")),
                DataColumn(label: Text("Start Date")),
                DataColumn(label: Text("Completed Date")),
                DataColumn(label: Text("Actions")),
              ],
              rows:
                  _filteredTasks.map((task) {
                    final id = task['task_id'];
                    final isEditing = _editingTaskId == id;

                    return DataRow(
                      cells: [
                        DataCell(
                          isEditing
                              ? TextField(controller: _titleCtrls[id])
                              : Text(task['title'] ?? ''),
                        ),
                        DataCell(
                          isEditing
                              ? TextField(controller: _descCtrls[id])
                              : Text(task['description'] ?? ''),
                        ),
                        DataCell(
                          isEditing
                              ? TextField(
                                controller: TextEditingController(
                                  text: task['assigned_by_name'] ?? '',
                                ),
                              )
                              : Text(task['assigned_by_name'] ?? 'N/A'),
                        ),
                        DataCell(
                          isEditing
                              ? TextField(
                                controller: TextEditingController(
                                  text: task['assigned_to_name'] ?? '',
                                ),
                              )
                              : Text(task['assigned_to_name'] ?? 'N/A'),
                        ),
                        DataCell(
                          isEditing
                              ? TextField(
                                controller: TextEditingController(
                                  text: task['department_name'] ?? '',
                                ),
                              )
                              : Text(task['department_name'] ?? 'N/A'),
                        ),
                        DataCell(
                          isEditing
                              ? TextField(controller: _priorityCtrls[id])
                              : Text(task['priority'] ?? ''),
                        ),
                        DataCell(
                          isEditing
                              ? TextField(controller: _statusCtrls[id])
                              : _statusChip(task['status'] ?? 'Unknown'),
                        ),
                        DataCell(
                          isEditing
                              ? TextField(
                                controller: _progressCtrls[id],
                                keyboardType: TextInputType.number,
                              )
                              : GestureDetector(
                                onTap: () => showProgressPopup(context, task),
                                child: Text(
                                  "${task['progress_percent']}% (click)",
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
                        // 🔹 Inside DataRow cells
                        DataCell(
                          isEditing
                              ? GestureDetector(
                                onTap: () async {
                                  DateTime initialDate =
                                      task['due_date'] ?? DateTime.now();
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: initialDate,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _dueDates[id] = picked;
                                      task['due_date'] = picked;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                    horizontal: 4,
                                  ),
                                  child: Text(
                                    task['due_date'] != null
                                        ? dateFormat.format(task['due_date'])
                                        : 'Select Due Date',
                                    style: const TextStyle(
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              )
                              : Text(
                                task['due_date'] != null
                                    ? dateFormat.format(task['due_date'])
                                    : '--',
                              ),
                        ),
                        DataCell(
                          isEditing
                              ? GestureDetector(
                                onTap: () async {
                                  DateTime initialDate =
                                      task['start_date'] ?? DateTime.now();
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: initialDate,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _startDates[id] = picked;
                                      task['start_date'] = picked;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                    horizontal: 4,
                                  ),
                                  child: Text(
                                    task['start_date'] != null
                                        ? dateFormat.format(task['start_date'])
                                        : 'Select Date',
                                    style: const TextStyle(
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              )
                              : Text(
                                task['start_date'] != null
                                    ? dateFormat.format(task['start_date'])
                                    : '--',
                              ),
                        ),
                        DataCell(
                          isEditing
                              ? GestureDetector(
                                onTap: () async {
                                  DateTime initialDate =
                                      task['completed_date'] ?? DateTime.now();
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: initialDate,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _completedDates[id] = picked;
                                      task['completed_date'] = picked;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                    horizontal: 4,
                                  ),
                                  child: Text(
                                    task['completed_date'] != null
                                        ? dateFormat.format(
                                          task['completed_date'],
                                        )
                                        : 'Select Completed Date',
                                    style: const TextStyle(
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              )
                              : Text(
                                task['completed_date'] != null
                                    ? dateFormat.format(task['completed_date'])
                                    : '--',
                              ),
                        ),

                        DataCell(
                          isAdmin
                              ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isEditing) ...[
                                    IconButton(
                                      icon: const Icon(
                                        Icons.check,
                                        color: Colors.green,
                                      ),
                                      onPressed: () => _saveTask(id),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.red,
                                      ),
                                      onPressed:
                                          () => setState(
                                            () => _editingTaskId = null,
                                          ),
                                    ),
                                  ] else ...[
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      onPressed:
                                          () => setState(
                                            () => _editingTaskId = id,
                                          ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _deleteTask(id),
                                    ),
                                  ],
                                ],
                              )
                              : const Text('-'),
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

  // 🔹 Save Task (with dates and progress)
  Future<void> _saveTask(String id) async {
    try {
      int progress = int.tryParse(_progressCtrls[id]?.text ?? '0') ?? 0;

      await FirebaseFirestore.instance.collection('tasks').doc(id).update({
        'title': _titleCtrls[id]?.text,
        'description': _descCtrls[id]?.text,
        'priority': _priorityCtrls[id]?.text,
        'status': _statusCtrls[id]?.text,
        'progress_percent': progress,
        'start_date':
            _startDates[id] != null
                ? Timestamp.fromDate(_startDates[id]!)
                : null,
        'due_date':
            _dueDates[id] != null ? Timestamp.fromDate(_dueDates[id]!) : null,
        'completed_date':
            _completedDates[id] != null
                ? Timestamp.fromDate(_completedDates[id]!)
                : null,
        'updated_at': FieldValue.serverTimestamp(),
      });

      setState(() => _editingTaskId = null);
      fetchTasks();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
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

          // 🔹 Filter & Refresh Row (Responsive)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Refresh button
                  ElevatedButton.icon(
                    onPressed: fetchTasks,
                    icon: const Icon(Icons.refresh),
                    label: const Text("Refresh"),
                  ),
                  const SizedBox(width: 16),

                  // Status filter
                  SizedBox(
                    width: 150, // adjust width as needed
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Status",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        DropdownButton<String>(
                          isExpanded: true,
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
                                    (f) => DropdownMenuItem(
                                      value: f,
                                      child: Text(f),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Assigned By filter
                  SizedBox(
                    width: 150,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Assigned By",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        DropdownButton<String>(
                          isExpanded: true,
                          value: _assignedByFilter,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _assignedByFilter = value);
                              applyFilter();
                            }
                          },
                          items:
                              assignedByOptions
                                  .map(
                                    (name) => DropdownMenuItem(
                                      value: name,
                                      child: Text(name),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ],
                    ),
                  ),

                  // Assigned To filter
                  SizedBox(
                    width: 150,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Assigned To",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        DropdownButton<String>(
                          isExpanded: true,
                          value: _assignedToFilter,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _assignedToFilter = value);
                              applyFilter();
                            }
                          },
                          items:
                              assignedToOptions
                                  .map(
                                    (name) => DropdownMenuItem(
                                      value: name,
                                      child: Text(name),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child:
                _isLoading
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
