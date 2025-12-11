import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AttendanceDashboardAllScreen extends StatefulWidget {
  final String currentUserId;
  final String currentUserRole;

  const AttendanceDashboardAllScreen({
    super.key,
    required this.currentUserId,
    required this.currentUserRole,
  });

  @override
  State<AttendanceDashboardAllScreen> createState() =>
      _AttendanceDashboardAllScreenState();
}

class _AttendanceDashboardAllScreenState
    extends State<AttendanceDashboardAllScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> employees = [];
  Map<String, Map<String, String>> attendanceTable = {};

  bool isLoading = false;

  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  late final List<int> years;
  final List<String> monthNames = List.generate(
    12,
    (i) => DateFormat.MMMM().format(DateTime(0, i + 1)),
  );

  int presentCount = 0;
  int absentCount = 0;
  int holidayCount = 0;
  int leaveCount = 0;

  @override
  void initState() {
    super.initState();
    final currentYear = DateTime.now().year;
    years = [for (int y = currentYear - 5; y <= currentYear + 1; y++) y];
    fetchData();
  }

  bool _isAdmin() {
    String r = widget.currentUserRole.toLowerCase();
    return r == 'admin' || r == 'super_admin' || r == 'superadmin';
  }

  Future<void> fetchData() async {
    setState(() => isLoading = true);

    await fetchEmployees();
    await generateAttendanceSheet();

    setState(() => isLoading = false);
  }

  // ---------------- FETCH EMPLOYEES ----------------
  Future<void> fetchEmployees() async {
    final snap = await _firestore.collection('employees').get();

    employees =
        snap.docs.map((d) {
          final data = d.data();
          return {'id': d.id, 'name': data['emp_name'] ?? "User"};
        }).toList();
  }

  // ---------------- GENERATE SHEET ----------------
 Future<void> generateAttendanceSheet() async {
  attendanceTable.clear();

  presentCount = 0;
  absentCount = 0;
  holidayCount = 0;
  leaveCount = 0;

  final start = DateTime(selectedYear, selectedMonth, 1);
  final end = DateTime(selectedYear, selectedMonth + 1, 0);

  for (var emp in employees) {
    String empId = emp['id'];
    Map<String, String> row = {};

    // Attendance from Firestore
    final recSnap = await _firestore
        .collection('attendance')
        .doc(empId)
        .collection('records')
        .get();

    Map<String, String> attendanceDates = {
      for (var d in recSnap.docs)
        (d.data()['date'] ?? d.id).toString():
            (d.data()['status'] ?? 'Present'),
    };

    // Holidays
    final holSnap = await _firestore.collection('holidays').get();
    final holidayDates = holSnap.docs.map((d) => d.id).toSet();

    // Leave
    final leaveSnap = await _firestore
        .collection('leave_applications')
        .doc(empId)
        .collection('applications')
        .where('status', isEqualTo: 'approved')
        .get();

    Set<String> leaveDates = {};
    for (var d in leaveSnap.docs) {
      final startDate = DateTime.parse(d['startDate']);
      final endDate = DateTime.parse(d['endDate']);

      DateTime temp = startDate;
      while (!temp.isAfter(endDate)) {
        leaveDates.add(DateFormat('yyyy-MM-dd').format(temp));
        temp = temp.add(const Duration(days: 1));
      }
    }

    DateTime day = start;
    while (!day.isAfter(end)) {
      String key = DateFormat('yyyy-MM-dd').format(day);
      String value = "A";

      if (attendanceDates.containsKey(key)) {
        value = "P";
        presentCount++;
      } else if (leaveDates.contains(key)) {
        value = "L";
        leaveCount++;
      } else if (holidayDates.contains(key)) {
        value = "H";
        holidayCount++;
      } else {
        value = "A";
        absentCount++;
      }

      row[day.day.toString()] = value;
      day = day.add(const Duration(days: 1));
    }

    attendanceTable[empId] = row;
  }
}

  // ---------------- EDIT POPUP ----------------
  void _showFullRowEditor(String empId, String empName) {
    final daysInMonth = DateTime(selectedYear, selectedMonth + 1, 0).day;
    Map<String, String> row = attendanceTable[empId] ?? {};

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Edit Attendance – $empName"),
              content: SizedBox(
                width: 550,
                height: 500,
                child: Scrollbar(
                  child: ListView.builder(
                    itemCount: daysInMonth,
                    itemBuilder: (context, index) {
                      final day = index + 1;
                      final key =
                          "${selectedYear}-${selectedMonth.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
                      String current = row["$day"] ?? "A";

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Day $day"),
                          DropdownButton<String>(
                            value: current,
                            items: const [
                              DropdownMenuItem(
                                value: "P",
                                child: Text("Present"),
                              ),
                              DropdownMenuItem(
                                value: "A",
                                child: Text("Absent"),
                              ),
                              DropdownMenuItem(
                                value: "L",
                                child: Text("Leave"),
                              ),
                              DropdownMenuItem(
                                value: "H",
                                child: Text("Holiday"),
                              ),
                            ],
                            onChanged: (v) {
                              row["$day"] = v!;
                              setState(() {});
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              actions: [
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  child: const Text("Save"),
                  onPressed: () async {
                    for (int d = 1; d <= daysInMonth; d++) {
                      final dateStr =
                          "${selectedYear}-${selectedMonth.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}";
                      final status = row["$d"] ?? "A";

                      await _firestore
                          .collection("attendance")
                          .doc(empId)
                          .collection("records")
                          .doc(dateStr)
                          .set({
                            "date": dateStr,
                            "status": status,
                          }, SetOptions(merge: true));
                    }

                    Navigator.pop(context);
                    fetchData();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------------- ADD HOLIDAY POPUP ----------------
  void _showAddHolidayDialog() {
    final dateCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Add Holiday"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    readOnly: true,
                    controller: dateCtrl,
                    decoration: const InputDecoration(
                      labelText: "Select Date",
                      suffixIcon: Icon(Icons.calendar_month),
                    ),
                    onTap: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: now,
                        firstDate: DateTime(now.year - 1),
                        lastDate: DateTime(now.year + 1),
                      );

                      if (picked != null) {
                        selectedDate = picked;
                        dateCtrl.text = DateFormat(
                          'yyyy-MM-dd',
                        ).format(selectedDate!);
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: "Holiday Name",
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (dateCtrl.text.isEmpty) return;

                    await _firestore
                        .collection("holidays")
                        .doc(dateCtrl.text)
                        .set({
                          "name": nameCtrl.text.trim(),
                          "created_at": DateTime.now().toIso8601String(),
                        });

                    Navigator.pop(context);
                    fetchData();
                  },
                  child: const Text("Add Holiday"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(selectedYear, selectedMonth + 1, 0).day;

    return Scaffold(
      appBar: AppBar(
         title: const Text(
    "Employee Attendance",
    style: TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w600,
    ),
  ),
  centerTitle: true,
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

      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Summary Cards
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        summaryCard("Present", presentCount, Colors.green),
                        summaryCard("Absent", absentCount, Colors.red),
                        summaryCard("Holiday", holidayCount, Colors.blue),
                        summaryCard("Leave", leaveCount, Colors.orange),
                      ],
                    ),
                  ),

                  // Filters Row
                  Row(
                    children: [
                      const SizedBox(width: 12),
                      // Month dropdown
                      DropdownButton<int>(
                        value: selectedMonth,
                        items: List.generate(
                          12,
                          (i) => DropdownMenuItem(
                            value: i + 1,
                            child: Text(monthNames[i]),
                          ),
                        ),
                        onChanged:
                            (v) => setState(
                              () => selectedMonth = v ?? selectedMonth,
                            ),
                      ),
                      const SizedBox(width: 12),
                      // Year dropdown
                      DropdownButton<int>(
                        value: selectedYear,
                        items:
                            years
                                .map(
                                  (y) => DropdownMenuItem(
                                    value: y,
                                    child: Text('$y'),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (v) => setState(
                              () => selectedYear = v ?? selectedYear,
                            ),
                      ),
                      const SizedBox(width: 12),
                      // Apply button
                      ElevatedButton(
                        onPressed: fetchData,
                        child: const Text("Apply"),
                      ),
                      const SizedBox(width: 12),
                      // Refresh icon
                      IconButton(
                        onPressed: fetchData,
                        icon: const Icon(Icons.refresh, color: Colors.blue),
                        tooltip: "Refresh",
                      ),
                      // Add holiday icon
                      if (_isAdmin())
                        IconButton(
                          onPressed: _showAddHolidayDialog,
                          icon: const Icon(
                            Icons.beach_access,
                            color: Colors.orange,
                          ),
                          tooltip: "Add Holiday",
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ---------------- TABLE ----------------
                  Expanded(
                    child: ScrollConfiguration(
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
                              headingRowColor: MaterialStateProperty.all(
                                Colors.grey.shade200,
                              ),
                              columns: [
                                const DataColumn(label: Text("Employee")),
                                ...List.generate(
                                  daysInMonth,
                                  (d) => DataColumn(label: Text("${d + 1}")),
                                ),
                                const DataColumn(label: Text("P")),
                                const DataColumn(label: Text("A")),
                                const DataColumn(label: Text("L")),
                                const DataColumn(label: Text("H")),
                                if (_isAdmin())
                                  const DataColumn(label: Text("Edit")),
                              ],
                              rows:
                                  employees.map((emp) {
                                    final data =
                                        attendanceTable[emp['id']] ?? {};

                                    int p = 0, a = 0, l = 0, h = 0;
                                    for (var v in data.values) {
                                      if (v == "P") p++;
                                      if (v == "A") a++;
                                      if (v == "L") l++;
                                      if (v == "H") h++;
                                    }

                                    return DataRow(
                                      cells: [
                                        DataCell(Text(emp['name'])),
                                        ...List.generate(daysInMonth, (d) {
                                          String value =
                                              data["${d + 1}"] ?? "-";
                                          return DataCell(
                                            Text(
                                              value,
                                              style: TextStyle(
                                                color:
                                                    value == "P"
                                                        ? Colors.green
                                                        : value == "A"
                                                        ? Colors.red
                                                        : value == "L"
                                                        ? Colors.orange
                                                        : value == "H"
                                                        ? Colors.blue
                                                        : Colors.grey,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            onTap:
                                                _isAdmin()
                                                    ? () => _showFullRowEditor(
                                                      emp['emp_id'], // If you manually stored emp_id
                                                      (d + 1) as String,
                                                    )
                                                    : null,
                                          );
                                        }),
                                        DataCell(Text("$p")),
                                        DataCell(Text("$a")),
                                        DataCell(Text("$l")),
                                        DataCell(Text("$h")),
                                        if (_isAdmin())
                                          DataCell(
                                            IconButton(
                                              icon: const Icon(Icons.edit,
                                              color: Colors.blue,),
                                              onPressed: () {
                                                _showFullRowEditor(
                                                  emp['id'],
                                                  emp['name'],
                                                );
                                              },
                                            ),
                                          ),
                                      ],
                                    );
                                  }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget summaryCard(String title, int count, Color color) {
    return Expanded(
      child: Card(
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(
                "$count",
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
