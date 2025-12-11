import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class EmployeeTaskReportScreen extends StatefulWidget {
  const EmployeeTaskReportScreen({super.key});

  @override
  State<EmployeeTaskReportScreen> createState() =>
      _EmployeeTaskReportScreenState();
}

class _EmployeeTaskReportScreenState extends State<EmployeeTaskReportScreen> {
  String? selectedEmployee;
  List<Map<String, dynamic>> employees = [];
  Map<String, int> taskCount = {};
  Map<String, double> completionRate = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchEmployees();
    fetchTaskReport();
  }

  /// ✅ Fetch all employees safely
  Future<void> fetchEmployees() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();

    setState(() {
      employees = snapshot.docs.map((doc) {
        final data = doc.data();
        final name = data['user_name'] ??
            data['emp_name'] ??
            data['name'] ??
            'Unknown User';
        return {'id': doc.id, 'name': name};
      }).toList();
    });
  }

  /// ✅ Fetch tasks & compute report safely
  Future<void> fetchTaskReport({String? filterEmployeeId}) async {
    setState(() => isLoading = true);

    final snapshot = await FirebaseFirestore.instance.collection('tasks').get();

    Map<String, int> total = {};
    Map<String, int> completed = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();

      final assignedToRef = data['assigned_to'] as DocumentReference?;
      if (assignedToRef == null) continue;

      final userId = assignedToRef.id;
      if (filterEmployeeId != null && userId != filterEmployeeId) continue;

      total[userId] = (total[userId] ?? 0) + 1;
      if (data['status'] == 'Completed') {
        completed[userId] = (completed[userId] ?? 0) + 1;
      }
    }

    Map<String, int> mappedCount = {};
    Map<String, double> mappedCompletion = {};

    for (var entry in total.entries) {
      final userSnap =
          await FirebaseFirestore.instance.collection('users').doc(entry.key).get();

      if (!userSnap.exists) continue;

      final userData = userSnap.data() ?? {};
      final name = userData['user_name'] ??
          userData['emp_name'] ??
          userData['name'] ??
          'Unknown User';

      mappedCount[name] = entry.value;
      mappedCompletion[name] =
          ((completed[entry.key] ?? 0) / entry.value) * 100;
    }

    setState(() {
      taskCount = mappedCount;
      completionRate = mappedCompletion;
      isLoading = false;
    });
  }

  /// ✅ Filter Dialog
  void showFilterDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Filter by Employee"),
          content: DropdownButtonFormField<String>(
            value: selectedEmployee,
            items: employees
                .map(
                  (e) => DropdownMenuItem<String>(
                    value: e['id'],
                    child: Text(e['name']),
                  ),
                )
                .toList(),
            onChanged: (val) => setState(() => selectedEmployee = val),
            decoration: const InputDecoration(labelText: 'Select Employee'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                fetchTaskReport(filterEmployeeId: selectedEmployee);
              },
              child: const Text("Apply"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final barData = taskCount.entries.toList();
    final pieData = completionRate.entries.toList();

    return Scaffold(
      appBar: const GradientAppBar(title: ""),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 🔹 Buttons Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: showFilterDialog,
                        icon: const Icon(Icons.filter_alt_rounded),
                        label: const Text("Filter"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() => selectedEmployee = null);
                          fetchTaskReport();
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text("Refresh"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  const Text(
                    "📊 Task Count per Employee",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // --- Bar Chart ---
                  if (barData.isEmpty)
                    const Text("No data available")
                  else
                    SizedBox(
                      height: 300,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: true),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (double value, meta) {
                                  if (value.toInt() < barData.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        barData[value.toInt()].key,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                          ),
                          barGroups: List.generate(
                            barData.length,
                            (i) => BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: barData[i].value.toDouble(),
                                  color: Colors.blueAccent,
                                  width: 18,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 40),
                  const Text(
                    "🥧 Task Completion Rate (%)",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // --- Pie Chart ---
                  if (pieData.isEmpty)
                    const Text("No data available")
                  else
                    SizedBox(
                      height: 300,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 4,
                          centerSpaceRadius: 50,
                          sections: pieData.map((entry) {
                            final color = Colors.primaries[
                                pieData.indexOf(entry) %
                                    Colors.primaries.length];
                            return PieChartSectionData(
                              color: color,
                              value: entry.value,
                              title:
                                  "${entry.key}\n${entry.value.toStringAsFixed(1)}%",
                              radius: 80,
                              titleStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final VoidCallback? onBackPressed;

  const GradientAppBar({
    super.key,
    required this.title,
    this.showBack = true,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: kToolbarHeight + 12,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              if (showBack)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white),
                  onPressed: onBackPressed ?? () => Navigator.pop(context),
                ),
              if (showBack) const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                height: 40,
                width: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  image: DecorationImage(
                    image: AssetImage('assets/logo.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 12);
}
