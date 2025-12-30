import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AttendanceDashboardForLoginUser extends StatefulWidget {
  final String currentUserId;
  final String currentUserRole;

  const AttendanceDashboardForLoginUser({
    super.key,
    required this.currentUserId,
    required this.currentUserRole,
  });

  @override
  State<AttendanceDashboardForLoginUser> createState() =>
      _AttendanceDashboardForLoginUserState();
}

class _AttendanceDashboardForLoginUserState
    extends State<AttendanceDashboardForLoginUser> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, Map<String, dynamic>> attendanceTable = {};
  Map<String, String> holidayMap = {};

  bool isLoading = false;

  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  late final List<int> years;
  final List<String> monthNames = List.generate(
    12,
    (i) => DateFormat.MMMM().format(DateTime(0, i + 1)),
  );

  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void initState() {
    super.initState();
    final currentYear = DateTime.now().year;
    years = [for (int y = currentYear - 5; y <= currentYear + 1; y++) y];
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() => isLoading = true);
    await fetchHolidays();
    await fetchAttendance();
    setState(() => isLoading = false);
  }

  Future<void> fetchHolidays() async {
    final snapshot = await _firestore.collection('holidays').get();
    holidayMap.clear();
    for (var doc in snapshot.docs) {
      holidayMap[doc.id] = doc['name'] ?? '';
    }
  }

  Future<void> fetchAttendance() async {
    attendanceTable.clear();
    final empId = widget.currentUserId;

    final snapshot = await _firestore
        .collection('attendance')
        .doc(empId)
        .collection('records')
        .get();

    attendanceTable[empId] = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final rawStatus = data['status'] ?? '-';

      String normalizedStatus;
      switch (rawStatus) {
        case 'Present':
        case 'P':
          normalizedStatus = 'P';
          break;
        case 'Absent':
        case 'A':
          normalizedStatus = 'A';
          break;
        case 'Leave':
        case 'L':
          normalizedStatus = 'L';
          break;
        case 'Holiday':
        case 'H':
          normalizedStatus = 'H';
          break;
        default:
          normalizedStatus = '-';
      }

      attendanceTable[empId]![doc.id] = {
        'status': normalizedStatus,
        'intime': data['intime'] ?? "-",
        'outtime': data['outtime'] ?? "-",
        'totalHours': data['totalHours'] ?? "-",
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final empId = widget.currentUserId;
    final daysInMonth = DateTime(selectedYear, selectedMonth + 1, 0).day;

    int presentCount = 0;
    int absentCount = 0;
    int leaveCount = 0;
    int holidayCount = 0;

    // Count summary
    for (int d = 1; d <= daysInMonth; d++) {
      final dateStr =
          "$selectedYear-${selectedMonth.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}";
      final value = holidayMap.containsKey(dateStr)
          ? "H"
          : attendanceTable[empId]?[dateStr]?['status'] ?? "-";

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

    return Scaffold(
      appBar:  AppBar(
        title: const Text(
          "My Attendance",
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

      body: isLoading
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

                // Month & Year Filters
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    children: [
                      DropdownButton<int>(
                        value: selectedMonth,
                        items: List.generate(
                          12,
                          (i) => DropdownMenuItem(
                            value: i + 1,
                            child: Text(monthNames[i]),
                          ),
                        ),
                        onChanged: (v) =>
                            setState(() => selectedMonth = v ?? selectedMonth),
                      ),
                      const SizedBox(width: 12),
                      DropdownButton<int>(
                        value: selectedYear,
                        items: years
                            .map((y) =>
                                DropdownMenuItem(value: y, child: Text('$y')))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => selectedYear = v ?? selectedYear),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: fetchData,
                        child: const Text("Apply"),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Attendance Table
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
                              const DataColumn(label: Text("Date")),
                              const DataColumn(label: Text("Status")),
                              const DataColumn(label: Text("In Time")),
                              const DataColumn(label: Text("Out Time")),
                              const DataColumn(label: Text("Total Hours")),
                            ],
                            rows: List.generate(daysInMonth, (d) {
                              final day = d + 1;
                              final dateStr =
                                  "$selectedYear-${selectedMonth.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";

                              final data = attendanceTable[empId]?[dateStr];
                              final status = data?['status'] ??
                                  (holidayMap.containsKey(dateStr) ? "H" : "-");
                              final intime = data?['intime'] ?? "-";
                              final outtime = data?['outtime'] ?? "-";
                              final totalHours = data?['totalHours'] ?? "-";

                              return DataRow(
                                cells: [
                                  DataCell(Text(dateStr)),
                                  DataCell(
                                    Text(
                                      status,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: status == "P"
                                            ? Colors.green
                                            : status == "A"
                                                ? Colors.red
                                                : status == "L"
                                                    ? Colors.orange
                                                    : status == "H"
                                                        ? Colors.blue
                                                        : Colors.grey,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(intime)),
                                  DataCell(Text(outtime)),
                                  DataCell(Text(totalHours)),
                                ],
                              );
                            }),
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
