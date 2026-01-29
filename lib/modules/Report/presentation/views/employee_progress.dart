import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class EmployeePerformanceDashboard extends StatefulWidget {
  const EmployeePerformanceDashboard({super.key});

  @override
  State<EmployeePerformanceDashboard> createState() =>
      _EmployeePerformanceDashboardState();
}

class _EmployeePerformanceDashboardState
    extends State<EmployeePerformanceDashboard> {
  bool loading = true;

  String? selectedEmployeeId;
  int selectedMonth = DateTime.now().month;

  final List<TaskTimeMetric> selectedEmployeeTasks = [];



  final Map<String, String> employees = {};
  final Map<String, List<double>> employeeScores = {};
  final List<MonthlyScore> singleEmployeeMonthlyAvg = [];

  final List<String> months = const [
    "",
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec"
  ];

  bool get isSingleEmployee => selectedEmployeeId != null;

  DateTime safeDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadEmployees() async {
    final snap =
        await FirebaseFirestore.instance.collection('employees').get();

    employees.clear();

    for (final doc in snap.docs) {
      final data = doc.data();
      if (data['role'] == 'intern') continue;

      final name = data['emp_name'];
      if (name != null) {
        employees[doc.id] = name.toString();
      }
    }
  }

  Future<void> loadDashboard() async {
    if (!mounted) return;
    setState(() => loading = true);

    employeeScores.clear();
    singleEmployeeMonthlyAvg.clear();
    selectedEmployeeTasks.clear();


    await loadEmployees();

    final taskSnap =
        await FirebaseFirestore.instance.collection('tasks').get();

    final Map<int, List<double>> monthWiseScores = {};

    for (final doc in taskSnap.docs) {
      final data = doc.data();
      if (data['status'] != 'Completed') continue;

      final empRef = data['assigned_to'] as DocumentReference?;
      if (empRef == null) continue;

      final empId = empRef.id;
      if (!employees.containsKey(empId)) continue;

      final completed = safeDate(data['completed_date']);
      final due = safeDate(data['due_date']);

      int delay =
          completed.isAfter(due) ? completed.difference(due).inDays : 0;

      double score =
          delay <= 0 ? 100.0 : (100 - delay * 10).clamp(40, 100).toDouble();

      // ---------- CURRENT / SELECTED MONTH ----------
      if (completed.month == selectedMonth) {
        // for all employees
        if (selectedEmployeeId == null) {
          employeeScores.putIfAbsent(empId, () => []).add(score);
        }

        // for selected employee
        if (selectedEmployeeId == empId) {
          monthWiseScores.putIfAbsent(completed.month, () => []).add(score);
        }
      }

      if (completed.month == selectedMonth &&
    selectedEmployeeId == empId) {

  final daysDiff = completed.difference(due).inDays;

  selectedEmployeeTasks.add(
    TaskTimeMetric(
      taskId: doc.id,
      daysDiff: daysDiff,
    ),
  );

  monthWiseScores.putIfAbsent(completed.month, () => []).add(score);
}

    }

    // Calculate average for selected employee for that month
    monthWiseScores.forEach((month, scores) {
      final avg = scores.reduce((a, b) => a + b) / scores.length;
      singleEmployeeMonthlyAvg
          .add(MonthlyScore(month: month, score: avg));
    });

    if (!mounted) return;
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:  AppBar(
        title: const Text(
          "Performance DashBoard",
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
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const SizedBox(height: 24),
                  filtersRow(),
                  const SizedBox(height: 24),
                  if (!isSingleEmployee) ...[
                    employeeComparisonChart(), // show current month for all employees
                    const SizedBox(height: 16),
                    employeeProgressList(),
                  ] else ...[
                    singleEmployeeMonthChart(),
                    const SizedBox(height: 24),
                     const SizedBox(height: 24),
  taskTimeBarChart(), // selected employee current/selected month
                  ],
                ],
              ),
            ),
    );
  }


late double avgDaysTaken = selectedEmployeeTasks
        .map((e) => e.daysDiff)
        .reduce((a, b) => a + b) /
    selectedEmployeeTasks.length;


Color getTaskColor(int diff, double avg) {
  if (diff <= avg) return Colors.green;
  if (diff <= avg + 3) return Colors.orange;
  return Colors.red;
}


Widget taskTimeBarChart() {
  if (selectedEmployeeTasks.isEmpty) {
    return const Text("No task timing data for this month");
  }

  final avgDaysTaken = selectedEmployeeTasks
          .map((e) => e.daysDiff)
          .reduce((a, b) => a + b) /
      selectedEmployeeTasks.length;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "⏱ Task Completion vs Avg Time (${avgDaysTaken.toStringAsFixed(1)} days)",
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 260,
        child: BarChart(
          BarChartData(
            minY: -15,
            maxY: 20,
            gridData: FlGridData(show: true),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) =>
                      Text("${v.toInt()}d"),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) =>
                      Text("T${v.toInt() + 1}"),
                ),
              ),
            ),
            barGroups: selectedEmployeeTasks
                .asMap()
                .entries
                .map((e) {
              final index = e.key;
              final diff = e.value.daysDiff;

              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: diff.toDouble(),
                    width: 18,
                    color: getTaskColor(diff, avgDaysTaken),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ],
              );
            }).toList(),
          ),
          swapAnimationDuration: const Duration(milliseconds: 800),
        ),
      ),
      const SizedBox(height: 8),
      Row(
        children: const [
          Icon(Icons.square, color: Colors.green, size: 12),
          SizedBox(width: 4),
          Text("Faster than avg"),
          SizedBox(width: 12),
          Icon(Icons.square, color: Colors.orange, size: 12),
          SizedBox(width: 4),
          Text("Near avg"),
          SizedBox(width: 12),
          Icon(Icons.square, color: Colors.red, size: 12),
          SizedBox(width: 4),
          Text("Slower"),
        ],
      ),
    ],
  );
}

  // ---------------- FILTERS ----------------

  Widget filtersRow() {
    return Row(
      children: [
        Expanded(child: employeeDropdown()),
        const SizedBox(width: 12),
        monthDropdown(),
      ],
    );
  }

  Widget employeeDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedEmployeeId,
      decoration: const InputDecoration(
        labelText: "Employee",
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text("All Employees")),
        ...employees.entries.map(
          (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
        ),
      ],
      onChanged: (v) {
        selectedEmployeeId = v;
        loadDashboard();
      },
    );
  }

  Widget monthDropdown() {
    return DropdownButton<int>(
      value: selectedMonth,
      items: List.generate(
        12,
        (i) => DropdownMenuItem(
          value: i + 1,
          child: Text(months[i + 1]),
        ),
      ),
      onChanged: (v) {
        selectedMonth = v!;
        loadDashboard();
      },
    );
  }

  // ---------------- COMPARISON CHART (All Employees, Current Month) ----------------

  Widget employeeComparisonChart() {
    if (employeeScores.isEmpty) {
      return const Text("No data for this month");
    }

    final avgScores = employeeScores.map(
      (k, v) => MapEntry(k, v.reduce((a, b) => a + b) / v.length),
    );

    final best =
        avgScores.entries.reduce((a, b) => a.value > b.value ? a : b);
    final worst =
        avgScores.entries.reduce((a, b) => a.value < b.value ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "🏆 Best / On Time: ${employees[best.key]} (${best.value.toStringAsFixed(1)}%)",
          style: const TextStyle(color: Colors.green),
        ),
        Text(
          "🚨 Delay : ${employees[worst.key]} (${worst.value.toStringAsFixed(1)}%)",
          style: const TextStyle(color: Colors.red),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 260,
          child: BarChart(
            BarChartData(
              maxY: 100,
              barGroups: avgScores.entries.toList().asMap().entries.map((e) {
                final empId = e.value.key;
                final score = e.value.value;
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: score,
                      width: 18,
                      color: empId == best.key
                          ? Colors.green
                          : empId == worst.key
                              ? Colors.red
                              : Colors.blue,
                    )
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------- EMPLOYEE PROGRESS LIST ----------------

  Widget employeeProgressList() {
    return Column(
      children: employeeScores.entries.map((e) {
        final avg =
            e.value.reduce((a, b) => a + b) / e.value.length;
        return ListTile(
          title: Text(employees[e.key]!),
          subtitle: LinearProgressIndicator(value: avg / 100),
          trailing: Text("${avg.toStringAsFixed(1)}%"),
        );
      }).toList(),
    );
  }

  // ---------------- SINGLE EMPLOYEE MONTH CHART ----------------

  Widget singleEmployeeMonthChart() {
    if (singleEmployeeMonthlyAvg.isEmpty) {
      return const Text("No data for this employee this month");
    }

    final score = singleEmployeeMonthlyAvg.first.score;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "📊 ${employees[selectedEmployeeId]!} Progress (${months[selectedMonth]})",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: score / 100,
          minHeight: 18,
          backgroundColor: Colors.grey.shade300,
          color: score >= 80
              ? Colors.green
              : score >= 60
                  ? Colors.orange
                  : Colors.red,
        ),
        const SizedBox(height: 8),
        Text("Score: ${score.toStringAsFixed(1)}%"),
      ],
    );
  }
}

// ---------------- MODEL ----------------

class MonthlyScore {
  final int month;
  final double score;

  MonthlyScore({required this.month, required this.score});
}


class TaskTimeMetric {
  final String taskId;
  final int daysDiff; // +delay, -early, 0 on-time

  TaskTimeMetric({required this.taskId, required this.daysDiff});
}
