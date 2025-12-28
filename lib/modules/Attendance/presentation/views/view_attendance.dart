import 'dart:ui';
import 'package:csv/csv.dart';
import 'dart:convert';
import 'dart:html' as html;

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

  String? editingEmpId;
  int? editingDay;

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
      final recSnap =
          await _firestore
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
      final leaveSnap =
          await _firestore
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

  String? resolveAttendanceValue({
    required DateTime cellDate,
    required Map<String, String> data,
    required int day,
  }) {
    final key = day.toString();
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final cellOnlyDate = DateTime(cellDate.year, cellDate.month, cellDate.day);

    final storedValue = data[key];

    // 🔹 FUTURE → always "-"
    if (cellOnlyDate.isAfter(todayDate)) {
      return "-";
    }

    // 🔹 TODAY → "-" until 12 PM, then "A"
    if (cellOnlyDate.isAtSameMomentAs(todayDate)) {
      final noon = DateTime(todayDate.year, todayDate.month, todayDate.day, 12);

      if (now.isAfter(noon)) {
        return storedValue == "P" || storedValue == "L" || storedValue == "H"
            ? storedValue
            : "A";
      }
      return "-";
    }

    // 🔹 PAST
    if (storedValue != null) {
      return storedValue;
    }

    return "A";
  }

  void exportAttendanceCSV() {
    final daysInMonth = DateTime(selectedYear, selectedMonth + 1, 0).day;

    List<List<String>> rows = [];

    // Header
    List<String> header = ["Employee"];
    for (int d = 1; d <= daysInMonth; d++) {
      header.add(d.toString());
    }
    header.addAll(["P", "A", "L", "H"]);
    rows.add(header);

    // Data
    for (var emp in employees) {
      final data = attendanceTable[emp['id']] ?? {};
      int p = 0, a = 0, l = 0, h = 0;

      List<String> row = [emp['name']];

      for (int d = 1; d <= daysInMonth; d++) {
        final cellDate = DateTime(selectedYear, selectedMonth, d);

        final value =
            resolveAttendanceValue(cellDate: cellDate, data: data, day: d) ??
            "-";

        row.add(value);

        if (value == "P") p++;
        if (value == "A") a++;
        if (value == "L") l++;
        if (value == "H") h++;
      }

      row.addAll([p.toString(), a.toString(), l.toString(), h.toString()]);
      rows.add(row);
    }

    final csvData = const ListToCsvConverter().convert(rows);

    final bytes = utf8.encode(csvData);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);

    html.AnchorElement(href: url)
      ..setAttribute(
        "download",
        "attendance_${selectedMonth}_$selectedYear.csv",
      )
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  Future<void> updateSingleDay({
    required String empId,
    required int day,
    required String status,
  }) async {
    final dateStr =
        "${selectedYear}-${selectedMonth.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";

    await _firestore
        .collection("attendance")
        .doc(empId)
        .collection("records")
        .doc(dateStr)
        .set({"date": dateStr, "status": status}, SetOptions(merge: true));

    setState(() {
      attendanceTable[empId]?[day.toString()] = status;
      editingEmpId = null;
      editingDay = null;
    });
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
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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
                      if (_isAdmin()) ...[
                        IconButton(
                          onPressed: _showAddHolidayDialog,
                          icon: const Icon(
                            Icons.beach_access,
                            color: Colors.orange,
                          ),
                          tooltip: "Add Holiday",
                        ),

                        IconButton(
                          onPressed: exportAttendanceCSV,
                          icon: const Icon(Icons.download, color: Colors.green),
                          tooltip: "Export Attendance",
                        ),
                      ],
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
                              headingRowColor: WidgetStateProperty.all(
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

                                        // -------- INLINE EDIT CELLS --------
                                        ...List.generate(daysInMonth, (d) {
                                          final day = d + 1;
                                          final cellDate = DateTime(
                                            selectedYear,
                                            selectedMonth,
                                            day,
                                          );

                                          final value = resolveAttendanceValue(
                                            cellDate: cellDate,
                                            data: data,
                                            day: day,
                                          );

                                          final isEditing =
                                              _isAdmin() &&
                                              editingEmpId == emp['id'] &&
                                              editingDay == day;

                                          return DataCell(
                                            isEditing
                                                ? DropdownButton<String>(
                                                  value: value,
                                                  underline: const SizedBox(),
                                                  items: const [
                                                    DropdownMenuItem(
                                                      value: "P",
                                                      child: Text("P"),
                                                    ),
                                                    DropdownMenuItem(
                                                      value: "A",
                                                      child: Text("A"),
                                                    ),
                                                    DropdownMenuItem(
                                                      value: "L",
                                                      child: Text("L"),
                                                    ),
                                                    DropdownMenuItem(
                                                      value: "H",
                                                      child: Text("H"),
                                                    ),
                                                  ],
                                                  onChanged: (v) {
                                                    if (v == null) return;
                                                    updateSingleDay(
                                                      empId: emp['id'],
                                                      day: day,
                                                      status: v,
                                                    );
                                                  },
                                                )
                                                : InkWell(
                                                  onTap:
                                                      _isAdmin()
                                                          ? () {
                                                            setState(() {
                                                              editingEmpId =
                                                                  emp['id'];
                                                              editingDay = day;
                                                            });
                                                          }
                                                          : null,
                                                  child: Text(
                                                    value!,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                                    ),
                                                  ),
                                                ),
                                          );
                                        }),

                                        // -------- TOTALS --------
                                        DataCell(Text("$p")),
                                        DataCell(Text("$a")),
                                        DataCell(Text("$l")),
                                        DataCell(Text("$h")),
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
