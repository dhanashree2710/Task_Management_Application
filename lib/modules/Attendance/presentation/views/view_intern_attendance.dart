import 'dart:ui';
import 'package:csv/csv.dart';
import 'dart:convert';
import 'dart:html' as html;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class InternAttendanceDashboardScreen extends StatefulWidget {
  final String currentUserId;
  final String currentUserRole;

  const InternAttendanceDashboardScreen({
    super.key,
    required this.currentUserId,
    required this.currentUserRole,
  });

  @override
  State<InternAttendanceDashboardScreen> createState() =>
      _InternAttendanceDashboardScreenState();
}

class _InternAttendanceDashboardScreenState
    extends State<InternAttendanceDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> interns = [];
  Map<String, Map<String, String>> attendanceTable = {};

  bool isLoading = false;

  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

   Map<String, String> holidayMap = {};

  String? editingEmpId;
  int? editingDay;

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

    await fetchInterns();
     await fetchHolidays();
    //  await generateAttendanceSheet();

    setState(() => isLoading = false);
  }

  // ---------------- FETCH INTERNS ----------------
  Future<void> fetchInterns() async {
    final snap = await _firestore.collection('interns').get();

    interns =
        snap.docs.map((d) {
          final data = d.data();
          return {'id': d.id, 'name': data['intern_name'] ?? "Intern"};
        }).toList();

    await fetchAttendance();
  }

  // --------------------------------------------------
  // 🔹 FETCH ATTENDANCE (CORRECT MAPPING)
  // --------------------------------------------------
 Future<void> fetchAttendance() async {
  attendanceTable.clear();

  for (final emp in interns) {
    final empId = emp['id'];

    print("🔵 Fetching attendance for intern: $empId");

    final snapshot = await _firestore
        .collection('attendance')
        .doc(empId)
        .collection('records')
        .get();

    attendanceTable[empId] = {};

    for (final doc in snapshot.docs) {
      print(
        "   📄 Firestore record → ${doc.id} : ${doc['status']}",
      );

      final rawStatus = doc['status'];

String normalizedStatus;
switch (rawStatus) {
  case 'Present':
    normalizedStatus = 'P';
    break;
  case 'Absent':
    normalizedStatus = 'A';
    break;
  case 'Leave':
    normalizedStatus = 'L';
    break;
  case 'Holiday':
    normalizedStatus = 'H';
    break;
  case 'P':
  case 'A':
  case 'L':
  case 'H':
    normalizedStatus = rawStatus;
    break;
  default:
    normalizedStatus = '-';
}

attendanceTable[empId]![doc.id] = normalizedStatus;

    }
  }
  

  print("✅ Attendance table loaded:");
  print(attendanceTable);

  setState(() {});
}


  void exportAttendanceCSV() {
    final daysInMonth = DateTime(selectedYear, selectedMonth + 1, 0).day;

    List<List<String>> rows = [];

    // Header
    List<String> header = ["Intern"];
    for (int d = 1; d <= daysInMonth; d++) {
      header.add(d.toString());
    }
    header.addAll(["P", "A", "L", "H"]);
    rows.add(header);

    // Data
    for (var emp in interns) {
      final data = attendanceTable[emp['id']] ?? {};
      int p = 0, a = 0, l = 0, h = 0;

      List<String> row = [emp['name']];

      for (int d = 1; d <= daysInMonth; d++) {
        final cellDate = DateTime(selectedYear, selectedMonth, d);

        final dateStr =
            "$selectedYear-${selectedMonth.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}";

        final value = holidayMap.containsKey(dateStr) ? "H" : data[dateStr] ?? "-";


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

  // 🔹 UPDATE SINGLE DAY
  // --------------------------------------------------
  Future<void> updateSingleDay({
    required String empId,
    required int day,
    required String status,
  }) async {
    final dateStr =
        "$selectedYear-${selectedMonth.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";

    await _firestore
        .collection("attendance")
        .doc(empId)
        .collection("records")
        .doc(dateStr)
        .set({"date": dateStr, "status": status}, SetOptions(merge: true));

    setState(() {
      attendanceTable.putIfAbsent(empId, () => {});
      attendanceTable[empId]![dateStr] = status;
      editingEmpId = null;
      editingDay = null;
    });
  }

 // ---------------- ADD HOLIDAY POPUP ----------------
void _showAddHolidayDialog() {
  final dateCtrl = TextEditingController();
  final nameCtrl = TextEditingController();

  showDialog(
    context: context,
    builder: (dialogContext) {
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
                final picked = await showDatePicker(
                  context: dialogContext,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(DateTime.now().year - 1),
                  lastDate: DateTime(DateTime.now().year + 1),
                );

                if (picked != null) {
                  dateCtrl.text =
                      DateFormat('yyyy-MM-dd').format(picked);
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (dateCtrl.text.isEmpty ||
                  nameCtrl.text.trim().isEmpty) {
                return;
              }

              await _firestore
                  .collection("holidays")
                  .doc(dateCtrl.text)
                  .set({
                "name": nameCtrl.text.trim(),
                "created_at": DateTime.now().toIso8601String(),
              });

              Navigator.pop(dialogContext);

              // 🔥 THIS IS IMPORTANT
              await fetchData(); // reload attendance + holidays
            },
            child: const Text("Add Holiday"),
          ),
        ],
      );
    },
  ).then((_) {
    dateCtrl.dispose();
    nameCtrl.dispose();
  });
}

Future<void> fetchHolidays() async {
  final snapshot = await _firestore.collection('holidays').get();

  holidayMap.clear();

  for (var doc in snapshot.docs) {
    holidayMap[doc.id] = doc['name'] ?? '';
  }

  debugPrint("🎉 Holidays Loaded: $holidayMap");

  setState(() {});
}


// ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
  final daysInMonth = DateTime(selectedYear, selectedMonth + 1, 0).day;

int presentCount = 0;
int absentCount = 0;
int leaveCount = 0;
int holidayCount = 0;

// Loop per employee
for (var emp in interns) {
  final empId = emp['id'];
  final data = attendanceTable[empId] ?? {};

  for (int d = 1; d <= daysInMonth; d++) {
    final dateStr =
        "$selectedYear-${selectedMonth.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}";

    final value = holidayMap.containsKey(dateStr)
        ? "H"
        : data[dateStr] ?? "-";

    switch (value) {
      case "P":
        presentCount++;
        break;
      case "A":
        absentCount++;
        break;
      case "L":
        leaveCount++;
        break;
      case "H":
        holidayCount++;
        break;
    }
  }
}


    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Intern Attendance",
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
                      ...[
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
                                  interns.map((emp) {
                                    final empId = emp['id'];
                                    final data = attendanceTable[empId] ?? {};

                                   int p = 0, a = 0, l = 0, h = 0;

for (int d = 1; d <= daysInMonth; d++) {
  final dateStr =
      "$selectedYear-${selectedMonth.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}";

  final value = holidayMap.containsKey(dateStr)
      ? "H"
      : data[dateStr] ?? "-";

  switch (value) {
    case "P":
      p++;
      break;
    case "A":
      a++;
      break;
    case "L":
      l++;
      break;
    case "H":
      h++;
      break;
  }
}


                                    return DataRow(
                                      cells: [
                                        DataCell(Text(emp['name'])),

                                        ...List.generate(daysInMonth, (d) {
                                          final day = d + 1;
                                          final dateStr =
                                              "$selectedYear-${selectedMonth.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";

                                          String value;

if (holidayMap.containsKey(dateStr)) {
  value = "H";
} else {
  value = data[dateStr] ?? "-";
}


                                          final isEditing =
                                              _isAdmin() &&
                                              editingEmpId == empId &&
                                              editingDay == day;

                                          return DataCell(
                                            isEditing
                                                ? DropdownButton<String>(
                                                  key: ValueKey("$empId-$day"),
                                                  value:
                                                      value == "-"
                                                          ? null
                                                          : value,
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
                                                      empId: empId,
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
                                                                  empId;
                                                              editingDay = day;
                                                            });
                                                          }
                                                          : null,
                                                  child: Text(
                                                    value,
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
