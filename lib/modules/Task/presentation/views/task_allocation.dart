import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:task_management_application/utils/common/pop_up_screen.dart';
import 'package:task_management_application/utils/components/kdrt_colors.dart';

class TaskAllocationScreen extends StatefulWidget {
  final String currentUserId;
  final String currentUserRole;

  const TaskAllocationScreen({
    super.key,
    required this.currentUserId,
    required this.currentUserRole,
  });

  @override
  State<TaskAllocationScreen> createState() => _TaskAllocationScreenState();
}

class _TaskAllocationScreenState extends State<TaskAllocationScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  String? _assignedBy;
  String? _assignedTo;
  String? _priority;
  String? _departmentId;
  DateTime? _dueDate;

  bool _isLoading = false;
  List<Map<String, dynamic>> _admins = [];
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _interns = [];
  List<Map<String, dynamic>> _departments = [];

  @override
  void initState() {
    super.initState();
    fetchUsers();
    fetchDepartments();
  }

  Future<void> fetchUsers() async {
    try {
      final adminSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', whereIn: ['admin', 'super admin'])
          .get();

      final empSnapshot =
          await FirebaseFirestore.instance.collection('employees').get();

      final internSnapshot =
          await FirebaseFirestore.instance.collection('interns').get();

      setState(() {
        _admins = adminSnapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  'name': doc['user_name'] ?? '',
                  'type': (doc['role'] ?? '').toString().toUpperCase(),
                })
            .toList();

        _employees = empSnapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  'name': doc['emp_name'] ?? '',
                  'type': 'EMPLOYEE',
                })
            .toList();

        _interns = internSnapshot.docs
    .map((doc) => {
          'id': doc.id,
          'name': doc.data().containsKey('intern_name')
              ? doc['intern_name']
              : doc.data().containsKey('name')
                  ? doc['name']
                  : doc.data().containsKey('user_name')
                      ? doc['user_name']
                      : 'Unknown Intern',
          'type': 'INTERN',
        })
    .toList();

            
      });
    } catch (e) {
      showCustomAlert(
        context,
        isSuccess: false,
        title: "Error",
        description: "Error fetching users: $e",
      );
    }
  }

  Future<void> fetchDepartments() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('departments').get();

      setState(() {
        _departments = snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  'name': doc['dept_name'] ?? '',
                })
            .toList();
      });
    } catch (e) {
      showCustomAlert(
        context,
        isSuccess: false,
        title: "Error",
        description: "Error fetching departments: $e",
      );
    }
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  // Future<void> saveTask() async {
  //   if (!_formKey.currentState!.validate()) return;

  //   if (_assignedBy == null || _assignedTo == null || _departmentId == null) {
  //     showCustomAlert(
  //       context,
  //       isSuccess: false,
  //       title: "Missing Details",
  //       description: "Please select Assigned By, Assigned To, and Department.",
  //     );
  //     return;
  //   }

  //   setState(() => _isLoading = true);

  //   try {
  //     final taskRef = FirebaseFirestore.instance.collection('tasks').doc();

  //     // ✅ Store as Firestore References
  //     final assignedByRef =
  //         FirebaseFirestore.instance.collection('users').doc(_assignedBy);
  //     final assignedToRef =
  //         FirebaseFirestore.instance.collection('users').doc(_assignedTo);
  //     final deptRef = FirebaseFirestore.instance
  //         .collection('departments')
  //         .doc(_departmentId);

  //     await taskRef.set({
  //       'task_id': taskRef.id,
  //       'title': _titleController.text.trim(),
  //       'description': _descController.text.trim(),
  //       'assigned_by': assignedByRef,
  //       'assigned_to': assignedToRef,
  //       'department_id': deptRef,
  //       'priority': _priority ?? '',
  //       'status': 'Pending',
  //       'progress_percent': '0',
  //       'due_date': _dueDate != null
  //           ? Timestamp.fromDate(_dueDate!)
  //           : FieldValue.serverTimestamp(),
  //       'created_at': FieldValue.serverTimestamp(),
  //       'updated_at': FieldValue.serverTimestamp(),
  //     });

  //     showCustomAlert(
  //       context,
  //       isSuccess: true,
  //       title: "Success",
  //       description: "Task allocated successfully!",
  //     );

  //     _titleController.clear();
  //     _descController.clear();
  //     setState(() {
  //       _assignedBy = null;
  //       _assignedTo = null;
  //       _priority = null;
  //       _departmentId = null;
  //       _dueDate = null;
  //     });
  //   } catch (e) {
  //     showCustomAlert(
  //       context,
  //       isSuccess: false,
  //       title: "Error",
  //       description: "Failed to allocate task: $e",
  //     );
  //   } finally {
  //     setState(() => _isLoading = false);
  //   }
  // }

  Future<void> saveTask() async {
  if (!_formKey.currentState!.validate()) return;

  if (_assignedBy == null || _assignedTo == null || _departmentId == null) {
    showCustomAlert(
      context,
      isSuccess: false,
      title: "Missing Details",
      description: "Please select Assigned By, Assigned To, and Department.",
    );
    return;
  }

  setState(() => _isLoading = true);

  try {
    final taskRef = FirebaseFirestore.instance.collection('tasks').doc();

    // Firestore references
    final assignedByRef =
        FirebaseFirestore.instance.collection('users').doc(_assignedBy);
    final assignedToRef =
        FirebaseFirestore.instance.collection('users').doc(_assignedTo);
    final deptRef =
        FirebaseFirestore.instance.collection('departments').doc(_departmentId);

    // ✅ Save task data
    await taskRef.set({
      'task_id': taskRef.id,
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'assigned_by': assignedByRef,
      'assigned_to': assignedToRef,
      'department_id': deptRef,
      'priority': _priority ?? '',
      'status': 'Pending',
      'progress_percent': '0',
      'due_date': _dueDate != null
          ? Timestamp.fromDate(_dueDate!)
          : FieldValue.serverTimestamp(),
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });

    // ✅ Create a notification for the assigned user
    final notifRef =
        FirebaseFirestore.instance.collection('notifications').doc();

    await notifRef.set({
      'notif_id': notifRef.id,
      'user_ref': assignedToRef, // notification receiver
      'task_ref': taskRef, // reference to the created task
      'title': "New Task Assigned",
      'message':
          "You have been assigned a new task: ${_titleController.text.trim()}",
      'is_read': false,
      'timestamp': FieldValue.serverTimestamp(),
    });

    showCustomAlert(
      context,
      isSuccess: true,
      title: "Success",
      description: "Task allocated successfully!",
    );

    _titleController.clear();
    _descController.clear();
    setState(() {
      _assignedBy = null;
      _assignedTo = null;
      _priority = null;
      _departmentId = null;
      _dueDate = null;
    });
  } catch (e) {
    showCustomAlert(
      context,
      isSuccess: false,
      title: "Error",
      description: "Failed to allocate task: $e",
    );
  } finally {
    setState(() => _isLoading = false);
  }
}


  InputDecoration gradientInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          width: 2,
          color: Color(0xFF22A4E0),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          width: 2,
          color: Color(0xFF34D0C6),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final assignByList = [..._admins, ..._employees];
    final assignToList = [..._employees, ..._interns];

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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEAF6FF), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Card(
                color: KDRTColors.white,
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(25),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Color(0xFF22A4E0), Color(0xFF1565C0)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds),
                            child: const Text(
                              "Task Allocation",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 25),

                        TextFormField(
                          controller: _titleController,
                          decoration:
                              gradientInputDecoration("Enter Task Title"),
                          validator: (value) =>
                              value!.isEmpty ? "Enter task title" : null,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _descController,
                          maxLines: 3,
                          decoration:
                              gradientInputDecoration("Enter Task Description"),
                        ),
                        const SizedBox(height: 16),
DropdownButtonFormField<String>(
  value: _departmentId,
  isExpanded: true, // 🔥 Fix overflow
  decoration: gradientInputDecoration("Select Department"),
  items: _departments
      .map((dept) => DropdownMenuItem<String>(
            value: dept['id'],
            child: Text(dept['name']),
          ))
      .toList(),
  onChanged: (value) => setState(() => _departmentId = value),
),
const SizedBox(height: 16),

DropdownButtonFormField<String>(
  value: _assignedBy,
  isExpanded: true, // 🔥 Fix overflow
  decoration: gradientInputDecoration("Assigned By"),
  items: assignByList
      .map((person) => DropdownMenuItem<String>(
            value: person['id'],
            child: Text("${person['name']} (${person['type']})"),
          ))
      .toList(),
  onChanged: (value) => setState(() => _assignedBy = value),
),
const SizedBox(height: 16),

DropdownButtonFormField<String>(
  value: _assignedTo,
  isExpanded: true, // 🔥 Fix overflow
  decoration: gradientInputDecoration("Assigned To"),
  items: assignToList
      .map((person) => DropdownMenuItem<String>(
            value: person['id'],
            child: Text("${person['name']} (${person['type']})"),
          ))
      .toList(),
  onChanged: (value) => setState(() => _assignedTo = value),
),
const SizedBox(height: 16),

DropdownButtonFormField<String>(
  value: _priority,
  isExpanded: true, // 🔥 Fix overflow
  decoration: gradientInputDecoration("Select Priority"),
  items: const [
    DropdownMenuItem(value: "High", child: Text("High")),
    DropdownMenuItem(value: "Medium", child: Text("Medium")),
    DropdownMenuItem(value: "Low", child: Text("Low")),
  ],
  onChanged: (value) => setState(() => _priority = value),
),
const SizedBox(height: 16),


                        InkWell(
                          onTap: () => _selectDueDate(context),
                          child: InputDecorator(
                            decoration:
                                gradientInputDecoration("Select Due Date"),
                            child: Text(
                              _dueDate == null
                                  ? "Tap to select date"
                                  : DateFormat('dd MMM yyyy')
                                      .format(_dueDate!),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        Center(
                          child: GestureDetector(
                            onTap: _isLoading ? null : saveTask,
                            child: Container(
                              width: double.infinity,
                              height: 55,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF34D0C6),
                                    Color(0xFF22A4E0),
                                    Color(0xFF1565C0)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              alignment: Alignment.center,
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : const Text(
                                      "Save Task",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
