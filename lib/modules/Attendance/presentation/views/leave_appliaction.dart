import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LeaveApplicationScreen extends StatefulWidget {
  final String currentUserId;
  final String currentUserRole;

  const LeaveApplicationScreen({
    super.key,
    required this.currentUserId,
    required this.currentUserRole,
  });

  @override
  State<LeaveApplicationScreen> createState() => _LeaveApplicationScreenState();
}

class _LeaveApplicationScreenState extends State<LeaveApplicationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();
  String? leaveType;
  DateTime? startDate;
  DateTime? endDate;
  String? reason;

  String? userName;
  bool isLoading = false;

   final LinearGradient gradient = const LinearGradient(
    colors: [
      Color(0xFF34D0C6),
      Color(0xFF22A4E0),
      Color(0xFF1565C0),
    ],
  );


  @override
  void initState() {
    super.initState();
    loadUserName();
  }

  /// Fetch employee/intern name
  Future<void> loadUserName() async {
    try {
      DocumentSnapshot userDoc;

      if (widget.currentUserRole.toLowerCase() == "employee") {
        userDoc = await _firestore
            .collection('employees')
            .doc(widget.currentUserId)
            .get();
        userName = userDoc.get('emp_name') ?? "User";
      } else {
        userDoc = await _firestore
            .collection('interns')
            .doc(widget.currentUserId)
            .get();
        userName = userDoc.get('intern_name') ?? "User";
      }

      setState(() {});
    } catch (e) {
      userName = "User";
    }
  }

  /// Submit leave request to Firestore
  Future<void> submitLeave() async {
    if (!_formKey.currentState!.validate()) return;
    if (startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select both dates")),
      );
      return;
    }

    setState(() => isLoading = true);

    final leaveId = DateTime.now().millisecondsSinceEpoch.toString();

    final leaveData = {
      "leaveId": leaveId,
      "userId": widget.currentUserId,
      "userName": userName,
      "role": widget.currentUserRole,
      "leaveType": leaveType,
      "startDate": DateFormat('yyyy-MM-dd').format(startDate!),
      "endDate": DateFormat('yyyy-MM-dd').format(endDate!),
      "reason": reason,
      "status": "Pending",
      "appliedOn": DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
    };

    await _firestore
        .collection("leave_applications")
        .doc(widget.currentUserId)
        .collection("applications")
        .doc(leaveId)
        .set(leaveData);

    setState(() => isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Leave Application Sent Successfully")),
    );

    Navigator.pop(context);
  }

  Future<void> pickStartDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() => startDate = picked);
    }
  }

  Future<void> pickEndDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: startDate ?? DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() => endDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
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
                      backgroundImage: AssetImage('assets/logo.png')),
              ),
            ],
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hello, ${userName ?? 'User'}",
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),

                    // Leave Type
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                          labelText: "Leave Type",
                          border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(
                            value: "Sick Leave", child: Text("Sick Leave")),
                        DropdownMenuItem(
                            value: "Casual Leave", child: Text("Casual Leave")),
                        DropdownMenuItem(
                            value: "Paid Leave", child: Text("Paid Leave")),
                        DropdownMenuItem(
                            value: "Emergency Leave",
                            child: Text("Emergency Leave")),
                      ],
                      value: leaveType,
                      onChanged: (v) => setState(() => leaveType = v),
                      validator: (v) =>
                          v == null ? "Please select leave type" : null,
                    ),
                    const SizedBox(height: 20),

                    // Start Date
                    ListTile(
                      shape: RoundedRectangleBorder(
                          side: const BorderSide(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8)),
                      title: const Text("Start Date"),
                      subtitle: Text(startDate == null
                          ? "Select Date"
                          : DateFormat('dd MMM yyyy').format(startDate!)),
                      trailing: const Icon(Icons.calendar_month),
                      onTap: pickStartDate,
                    ),
                    const SizedBox(height: 15),

                    // End Date
                    ListTile(
                      shape: RoundedRectangleBorder(
                          side: const BorderSide(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8)),
                      title: const Text("End Date"),
                      subtitle: Text(endDate == null
                          ? "Select Date"
                          : DateFormat('dd MMM yyyy').format(endDate!)),
                      trailing: const Icon(Icons.calendar_month),
                      onTap: pickEndDate,
                    ),
                    const SizedBox(height: 20),

                    // Reason
                    TextFormField(
                      maxLines: 4,
                      decoration: const InputDecoration(
                          labelText: "Reason",
                          border: OutlineInputBorder()),
                      onChanged: (v) => reason = v,
                      validator: (v) => v == null || v.isEmpty
                          ? "Please enter reason"
                          : null,
                    ),
                    const SizedBox(height: 25),

                    // Submit Button
                      GestureDetector(
              onTap: submitLeave,
              child: Container(
                width: double.infinity,
                height: 55,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(15),
                ),
                alignment: Alignment.center,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Submit",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
              ),
            ),
                  ],
                ),
              ),
            ),
    );
  }
}
