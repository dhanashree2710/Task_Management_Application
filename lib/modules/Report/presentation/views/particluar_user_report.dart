import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class EmployeeTaskReportScreen extends StatelessWidget {
  final String employeeId;
  const EmployeeTaskReportScreen({super.key, required this.employeeId});

  // ================= SAFE HELPERS =================
  int safeInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  DateTime safeDate(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.now();
  }

  String durationText(DateTime start, DateTime end) {
    final d = end.difference(start);
    return "${d.inHours}h ${d.inMinutes.remainder(60)}m";
  }

  @override
  Widget build(BuildContext context) {
    final employeeRef = FirebaseFirestore.instance.doc('users/$employeeId');

    return Scaffold(
      appBar:  AppBar(
        title: const Text(
          "Task Report",
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

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tasks')
            .where('assigned_to', isEqualTo: employeeRef)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No tasks found"));
          }

          final tasks = snapshot.data!.docs;

          // --- Compute Status Counts ---
          int completed = 0, inProgress = 0, pending = 0;
          for (var task in tasks) {
            final status = task['status'] ?? 'Pending';
            if (status == 'Completed') completed++;
            else if (status == 'In Progress') inProgress++;
            else pending++;
          }

          final totalTasks = completed + inProgress + pending;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ======= STATUS CARDS =======
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _statusCard("Completed", completed, Colors.green),
                    _statusCard("In Progress", inProgress, Colors.orange),
                    _statusCard("Pending", pending, Colors.red),
                  ],
                ),
                const SizedBox(height: 20),

                // ======= PIE CHART =======
                SizedBox(
                  height: 220,
                  child: PieChart(
                    PieChartData(
                      centerSpaceRadius: 40,
                      sectionsSpace: 4,
                      sections: [
                        PieChartSectionData(
                          color: Colors.green,
                          value: completed.toDouble(),
                          title: "$completed",
                          radius: 60,
                          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        PieChartSectionData(
                          color: Colors.orange,
                          value: inProgress.toDouble(),
                          title: "$inProgress",
                          radius: 60,
                          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        PieChartSectionData(
                          color: Colors.red,
                          value: pending.toDouble(),
                          title: "$pending",
                          radius: 60,
                          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ======= TASK LIST =======
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final taskData = tasks[index].data() as Map<String, dynamic>;
                    final title = taskData['title'] ?? "Untitled Task";
                    final status = taskData['status'] ?? "Pending";
                    final progress = safeInt(taskData['progress']);
                    final startDate = safeDate(taskData['start_date']);
                    final dueDate = safeDate(taskData['due_date']);
                    final completedDate = status == "Completed"
                        ? safeDate(taskData['completed_date'])
                        : DateTime.now();
                    final totalTime = durationText(startDate, completedDate);

                    final timelineFuture = FirebaseFirestore.instance
                        .collection('reports')
                        .where('task_id', isEqualTo: tasks[index].id)
                        .get();

                    return FutureBuilder<QuerySnapshot>(
                      future: timelineFuture,
                      builder: (context, reportSnapshot) {
                        List<Map<String, dynamic>> timeline = [];
                        if (reportSnapshot.hasData) {
                          for (var r in reportSnapshot.data!.docs) {
                            final rep = r.data() as Map<String, dynamic>;
                            timeline.add({
                              'description': rep['description'] ?? 'No description',
                              'progress_percent': safeInt(rep['progress_percent']),
                              'timestamp': safeDate(rep['timestamp'] ?? rep['date'] ?? rep['start_date']),
                            });
                          }

                          if (!timeline.any((e) => safeInt(e['progress_percent']) == 0)) {
                            timeline.insert(0, {'description': 'Task started', 'progress_percent': 0, 'timestamp': startDate});
                          }
                          if (status == 'Completed' &&
                              !timeline.any((e) => safeInt(e['progress_percent']) == 100)) {
                            timeline.add({'description': 'Task completed', 'progress_percent': 100, 'timestamp': completedDate});
                          }

                          timeline.sort((a, b) => safeDate(a['timestamp']).compareTo(safeDate(b['timestamp'])));
                        }

                        Color cardColor;
                        if (status == "Completed") cardColor = Colors.green.shade400;
                        else if (status == "In Progress") cardColor = Colors.orange.shade400;
                        else cardColor = Colors.grey.shade500;

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: status == "Completed"
                                  ? [Colors.green.shade400, Colors.green.shade700]
                                  : status == "In Progress"
                                      ? [Colors.orange.shade400, Colors.orange.shade700]
                                      : [Colors.grey.shade400, Colors.grey.shade600],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Text(
                                    status,
                                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text("Start: ${startDate.toLocal().toString().split(' ')[0]}", style: const TextStyle(color: Colors.white70)),
                              Text("Due: ${dueDate.toLocal().toString().split(' ')[0]}", style: const TextStyle(color: Colors.white70)),
                              if (status == "Completed")
                                Text("Completed: ${completedDate.toLocal().toString().split(' ')[0]}", style: const TextStyle(color: Colors.white70)),
                              const SizedBox(height: 8),
                              Text("Total Time: $totalTime", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 12),

                              if (timeline.isNotEmpty)
                                Row(
                                  children: timeline.map<Widget>((step) {
                                    int progressPercent = safeInt(step['progress_percent']);
                                    Color stepColor = progressPercent == 100
                                        ? Colors.green
                                        : progressPercent >= 50
                                            ? Colors.orange
                                            : Colors.red;
                                    return Expanded(
                                      child: Column(
                                        children: [
                                          Container(
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: stepColor,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text("$progressPercent%", style: const TextStyle(fontSize: 10, color: Colors.white)),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: progress / 100,
                                  minHeight: 10,
                                  backgroundColor: Colors.white30,
                                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text("$progress%", style: const TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===== STATUS CARD =====
  Widget _statusCard(String title, int count, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6, offset: const Offset(0, 3))],
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(count.toString(), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
