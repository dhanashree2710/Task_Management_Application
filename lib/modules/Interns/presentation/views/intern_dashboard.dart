import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:task_management_application/modules/Notification/presentation/views/notification_history_screen.dart';
import 'package:task_management_application/utils/common/appbar_drawer.dart';
import 'package:uuid/uuid.dart';

class InternDashboardScreen extends StatefulWidget {
  final String currentUserId;
  final String currentUserRole;

  const InternDashboardScreen({
    super.key,
    required this.currentUserId,
    required this.currentUserRole,
  });

  @override
  State<InternDashboardScreen> createState() => _InternDashboardScreenState();
}

class _InternDashboardScreenState extends State<InternDashboardScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   String selectedStatus = 'Pending';
//   DateTime? _startFilterDate;
//   DateTime? _endFilterDate;
//   String? _assignedByFilter;
//   String? _deptFilter;
//   String? _priorityFilter;
//   String? _titleFilter;

//   final List<String> priorities = ['High', 'Medium', 'Low'];

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 3, vsync: this);
//   }

//   Future<void> _refreshData({bool clearFilters = false}) async {
//     if (clearFilters) {
//       _startFilterDate = null;
//       _endFilterDate = null;
//       _priorityFilter = null;
//       _deptFilter = null;
//       _titleFilter = null;
//       _assignedByFilter = null;
//     }
//     setState(() {});
//   }

//   Stream<QuerySnapshot> _getTasksByStatus(String status) {
//     Query query = FirebaseFirestore.instance
//         .collection('tasks')
//         .where('status', isEqualTo: status)
//         .where('assigned_to', whereIn: [
//       widget.currentUserId,
//       FirebaseFirestore.instance.doc("/users/${widget.currentUserId}")
//     ]);

//     if (_startFilterDate != null) {
//       query = query.where('due_date',
//           isGreaterThanOrEqualTo: Timestamp.fromDate(_startFilterDate!));
//     }
//     if (_endFilterDate != null) {
//       query = query.where('due_date',
//           isLessThanOrEqualTo: Timestamp.fromDate(_endFilterDate!));
//     }
//     if (_deptFilter != null && _deptFilter!.isNotEmpty) {
//       query = query.where('dept_name', isEqualTo: _deptFilter);
//     }
//     if (_priorityFilter != null && _priorityFilter!.isNotEmpty) {
//       query = query.where('priority', isEqualTo: _priorityFilter);
//     }
//     if (_titleFilter != null && _titleFilter!.isNotEmpty) {
//       query = query.where('title', isEqualTo: _titleFilter);
//     }
//     if (_assignedByFilter != null && _assignedByFilter!.isNotEmpty) {
//       query = query.where('assigned_by_name', isEqualTo: _assignedByFilter);
//     }

//     return query.snapshots();
//   }

//   Future<String> _getAssignedByName(DocumentReference assignedByRef) async {
//     try {
//       final snapshot = await assignedByRef.get();
//       final data = snapshot.data() as Map<String, dynamic>?;
//       return data?['user_name'] ?? 'Unknown';
//     } catch (e) {
//       return 'Unknown';
//     }
//   }

//   Future<void> _selectDate(BuildContext context, DateTime? initialDate,
//       Function(DateTime) onSelected) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: initialDate ?? DateTime.now(),
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2100),
//     );
//     if (picked != null) onSelected(picked);
//   }

//   void _openFilterDialog() async {
//     DateTime? tempStart = _startFilterDate;
//     DateTime? tempEnd = _endFilterDate;
//     String? tempPriority = _priorityFilter;
//     String? tempDept = _deptFilter;
//     String? tempAssignedBy = _assignedByFilter;
//     String? tempTitle = _titleFilter;

//     final deptList = await _getDistinctValues('tasks', 'dept_name');
//     final titleList = await _getDistinctValues('tasks', 'title');
//     final assignedByList = await _getDistinctAssignedByNames();

//     await showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("Filter Tasks"),
//         content: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               DropdownButtonFormField<String>(
//                 value: tempTitle,
//                 decoration: const InputDecoration(labelText: "Title"),
//                 items: [
//                   const DropdownMenuItem(value: null, child: Text("All")),
//                   ...titleList
//                       .map((t) => DropdownMenuItem(value: t, child: Text(t))),
//                 ],
//                 onChanged: (val) => tempTitle = val,
//               ),
//               const SizedBox(height: 8),
//               DropdownButtonFormField<String>(
//                 value: tempDept,
//                 decoration: const InputDecoration(labelText: "Department"),
//                 items: [
//                   const DropdownMenuItem(value: null, child: Text("All")),
//                   ...deptList
//                       .map((d) => DropdownMenuItem(value: d, child: Text(d))),
//                 ],
//                 onChanged: (val) => tempDept = val,
//               ),
//               const SizedBox(height: 8),
//               DropdownButtonFormField<String>(
//                 value: tempAssignedBy,
//                 decoration: const InputDecoration(labelText: "Assigned By"),
//                 items: [
//                   const DropdownMenuItem(value: null, child: Text("All")),
//                   ...assignedByList
//                       .map((a) => DropdownMenuItem(value: a, child: Text(a))),
//                 ],
//                 onChanged: (val) => tempAssignedBy = val,
//               ),
//               const SizedBox(height: 8),
//               DropdownButtonFormField<String>(
//                 decoration: const InputDecoration(labelText: "Priority"),
//                 value: tempPriority,
//                 items: [
//                   const DropdownMenuItem(value: null, child: Text("All")),
//                   ...priorities
//                       .map((p) => DropdownMenuItem(value: p, child: Text(p))),
//                 ],
//                 onChanged: (val) => tempPriority = val,
//               ),
//               const SizedBox(height: 8),
//               Row(
//                 children: [
//                   Expanded(
//                     child: TextButton(
//                       onPressed: () =>
//                           _selectDate(context, tempStart, (picked) {
//                         setState(() => tempStart = picked);
//                       }),
//                       child: Text(tempStart == null
//                           ? "Start Date"
//                           : "${tempStart!.day}/${tempStart!.month}/${tempStart!.year}"),
//                     ),
//                   ),
//                   Expanded(
//                     child: TextButton(
//                       onPressed: () => _selectDate(context, tempEnd, (picked) {
//                         setState(() => tempEnd = picked);
//                       }),
//                       child: Text(tempEnd == null
//                           ? "End Date"
//                           : "${tempEnd!.day}/${tempEnd!.month}/${tempEnd!.year}"),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               setState(() {
//                 _startFilterDate = tempStart;
//                 _endFilterDate = tempEnd;
//                 _priorityFilter = tempPriority;
//                 _deptFilter = tempDept;
//                 _titleFilter = tempTitle;
//                 _assignedByFilter = tempAssignedBy;
//               });
//               Navigator.pop(context);
//             },
//             child: const Text("Apply"),
//           ),
//           TextButton(
//             onPressed: () {
//               _refreshData(clearFilters: true);
//               Navigator.pop(context);
//             },
//             child: const Text("Clear"),
//           ),
//         ],
//       ),
//     );
//   }

//   // 🔹 Notification logic (same as Employee)
//   Future<List<Map<String, dynamic>>> _fetchUnreadNotifications() async {
//     final snapshot = await FirebaseFirestore.instance
//         .collection('notifications')
//         .where('user_ref',
//             isEqualTo:
//                 FirebaseFirestore.instance.doc('users/${widget.currentUserId}'))
//         .where('is_read', isEqualTo: false)
//         .orderBy('timestamp', descending: true)
//         .get();

//     return snapshot.docs
//         .map((doc) => {'id': doc['notif_id'], ...doc.data()})
//         .toList();
//   }

//   void _showNotifications() async {
//     final notifications = await _fetchUnreadNotifications();
//     if (notifications.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("No new notifications")));
//       return;
//     }

//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("Notifications"),
//         content: SizedBox(
//           width: double.maxFinite,
//           child: ListView.builder(
//             shrinkWrap: true,
//             itemCount: notifications.length,
//             itemBuilder: (context, index) {
//               final notif = notifications[index];
//               return ListTile(
//                 title: Text(notif['title'] ?? ''),
//                 subtitle: Text(notif['message'] ?? ''),
//                 trailing: Text(
//                   notif['timestamp'] != null
//                       ? (notif['timestamp'] as Timestamp)
//                           .toDate()
//                           .toLocal()
//                           .toString()
//                       : '',
//                   style: const TextStyle(fontSize: 10),
//                 ),
//                 onTap: () async {
//                   await FirebaseFirestore.instance
//                       .collection('notifications')
//                       .doc(notif['notif_id'])
//                       .update({'is_read': true});
//                   Navigator.pop(context);
//                   _refreshData();
//                 },
//               );
//             },
//           ),
//         ),
//         actions: [
//           TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text("Close"))
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final isMobile = screenWidth < 600;
//     final isTablet = screenWidth >= 600 && screenWidth < 900;

//     return Scaffold(
//       body: CommonScaffold(
//         title: "",
//         role: widget.currentUserRole,
//         body: Column(
//           children: [
//              Padding(
//   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//   child: LayoutBuilder(
//     builder: (context, constraints) {
//       final screenWidth = constraints.maxWidth;
//       final isMobile = screenWidth < 600;

//       return Row(
//         mainAxisAlignment:
//             isMobile ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           // 🟦 Task Text (left for mobile, centered for desktop)
//           Expanded(
//             child: Align(
//               alignment:
//                   isMobile ? Alignment.centerLeft : Alignment.center,
//               child: ShaderMask(
//                 shaderCallback: (bounds) => const LinearGradient(
//                   colors: [
//                     Color(0xFF34D0C6),
//                     Color(0xFF22A4E0),
//                     Color(0xFF1565C0),
//                   ],
//                 ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
//                 child: Text(
//                   "Task",
//                   style: TextStyle(
//                     fontSize: isMobile ? 22 : 26,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white, // overridden by gradient
//                   ),
//                 ),
//               ),
//             ),
//           ),

//           // 🟩 Action Icons (always right-aligned)
//           Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // _iconButton(Icons.notifications, _showNotifications),
//               const SizedBox(width: 12),
//               _iconButton(Icons.filter_list, _openFilterDialog),
//               const SizedBox(width: 12),
//               _iconButton(Icons.refresh, () => _refreshData(clearFilters: true)),
//             ],
//           ),
//         ],
//       );
//     },
//   ),
// ),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               child: TabBar(
//                 controller: _tabController,
//                 indicator: BoxDecoration(
//                   color: _getTabColor(selectedStatus),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 labelColor: Colors.white,
//                 unselectedLabelColor: Colors.black87,
//                 tabs: const [
//                   Tab(child: Text("Pending")),
//                   Tab(child: Text("In Progress")),
//                   Tab(child: Text("Completed")),
//                 ],
//                 onTap: (index) {
//                   setState(() {
//                     selectedStatus = index == 0
//                         ? 'Pending'
//                         : index == 1
//                             ? 'In Progress'
//                             : 'Completed';
//                   });
//                 },
//               ),
//             ),
//             Expanded(
//               child: StreamBuilder<QuerySnapshot>(
//                 stream: _getTasksByStatus(selectedStatus),
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return const Center(
//                         child: CircularProgressIndicator());
//                   }
//                   if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                     return const Center(child: Text("No tasks found."));
//                   }
//                   final tasks = snapshot.data!.docs;
//                   int crossAxisCount = isMobile ? 1 : isTablet ? 2 : 3;

//                   return GridView.builder(
//                     padding: const EdgeInsets.all(12),
//                     gridDelegate:
//                         SliverGridDelegateWithFixedCrossAxisCount(
//                       crossAxisCount: crossAxisCount,
//                       crossAxisSpacing: 16,
//                       mainAxisSpacing: 16,
//                       childAspectRatio: isMobile ? 1.2 : 1.6,
//                     ),
//                     itemCount: tasks.length,
//                     itemBuilder: (context, index) {
//                       final data =
//                           tasks[index].data() as Map<String, dynamic>;
//                       return _buildTaskCard(data);
//                     },
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // 🧩 Helpers and task card builder
//   Widget _iconButton(IconData icon, VoidCallback onPressed) {
//     return Container(
//       width: 40,
//       height: 40,
//       decoration: _gradientBoxDecoration(),
//       child: IconButton(
//         icon: Icon(icon, color: Colors.white),
//         onPressed: onPressed,
//       ),
//     );
//   }

//   BoxDecoration _gradientBoxDecoration() => const BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             Color(0xFF34D0C6),
//             Color(0xFF22A4E0),
//             Color(0xFF1565C0),
//           ],
//         ),
//         borderRadius: BorderRadius.all(Radius.circular(8)),
//       );

//   Color _getTabColor(String status) {
//     switch (status) {
//       case 'Pending':
//         return Colors.orange;
//       case 'In Progress':
//         return Colors.blue;
//       case 'Completed':
//         return Colors.green;
//       default:
//         return Colors.grey;
//     }
//   }

// Widget _buildTaskCard(Map<String, dynamic> task)
//  { 
//    final status = task['status'] ?? 'Pending';
//    String progress = (task['progress_percent'] ?? '0').toString();
//    final dueDate = (task['due_date'] as Timestamp?)?.toDate();
//    final startDate = (task['start_date'] as Timestamp?)?.toDate(); 
//    final completedDate = (task['completed_date'] as Timestamp?)?.toDate(); 
//    final assignedByRef = task['assigned_by'] as DocumentReference?; 
//    final deptRef = task['department_id'] as DocumentReference?;
//    final validProgressValues = List.generate(11, (i) => (i * 10).toString()); 
//   if (!validProgressValues.contains(progress)) 
//    progress = '0'; 
//    final isOverdue = dueDate != null && completedDate == null && DateTime.now().isAfter( DateTime(dueDate.year, dueDate.month, dueDate.day) .add(const Duration(days: 1)), ); 
//    final priority = task['priority'] ?? 'N/A'; 
//     // 🔹 Fetch assignedByName and deptName together 
//    return FutureBuilder<Map<String, String>>(
//    future: () async {
//      String assignedByName = 'Unknown';
//      String deptName = 'Unknown'; 
//      if (assignedByRef != null) 
//        { 
//         assignedByName = await _getAssignedByName(assignedByRef); 
//        } 
//      if (deptRef != null) 
//     { 
//      final deptSnapshot = await deptRef.get(); 
//      final deptData = deptSnapshot.data() as Map<String, dynamic>?; 
//     deptName = deptData?['dept_name'] ?? 'Unknown'; 
//      }
//     return { 'assignedBy': assignedByName, 'department': deptName, }; 
//     }
//     (),
//      builder: (context, snapshot)
//       { 
//       if (!snapshot.hasData) 
//       {
//    return const Center(
//   child: CircularProgressIndicator()); 
//    }
//    final assignedByName = snapshot.data!['assignedBy'] ?? 'Unknown';
//   final deptName = snapshot.data!['department'] ?? 'Unknown'; 
//   return Card(
//   color: Colors.white,
//   shape: RoundedRectangleBorder
//    (
//     borderRadius: BorderRadius.circular(16)), 
//       elevation: 4,
//       child: Padding( 
//        padding: const EdgeInsets.all(14),
//        child: SingleChildScrollView(
//         child: Column( 
//        crossAxisAlignment: CrossAxisAlignment.start, 
//          children: [
//          Text(task['title'] ?? 'No Title', 
//          style: const TextStyle( fontSize: 20, fontWeight: FontWeight.bold)),
//          const SizedBox(height: 6), 
//          Text(
//           task['description'] ?? 'No Description', 
//           style: const TextStyle(fontSize: 16)), 
//           const SizedBox(height: 10), 
//          Text("Department: $deptName"), 
//           const SizedBox(height: 6), 
//           Text("Priority: $priority", 
//           style: TextStyle( 
//           color: priority == 'High' ? Colors.red : priority == 'Medium' ? Colors.orange : Colors.green)), 
//           const SizedBox(height: 6), 
//           Text("Assigned By: $assignedByName", 
//           style: const TextStyle(fontWeight: FontWeight.bold)), 
//           const SizedBox(height: 6), 
//           Text( "Due Date: ${dueDate != null ? _formatDate(dueDate) : '-'}", 
//           style: TextStyle(color: isOverdue ? Colors.red : Colors.black), ),
//           const SizedBox(height: 6), 
//           Text( "Start Date: ${startDate != null ? _formatDate(startDate) : '-'}"), 
//           const SizedBox(height: 6),
//           Text( "Completion Date: ${completedDate != null ? _formatDate(completedDate) : '-'}"), 
//           const SizedBox(height: 12), 
//          // 🔹 Set Start Date button 
//          if (startDate == null)
//          _gradientButton("Set Start Date", startDate, (_) async {
//          final now = DateTime.now(); 
//          await FirebaseFirestore.instance .collection('tasks') .doc(task['task_id']) .update({ 'start_date': Timestamp.fromDate(now), 'status': 'In Progress', });
//          await _storeReportData( userId: widget.currentUserId, 
//          progressPercent: '0', 
//          taskId: task['task_id'], 
//          startDate: now, );
//         _refreshData(); }),
//          // 🔹 Set Completion Date button 
//         if (startDate != null && completedDate == null)
//         _gradientButton("Set Completion Date", 
//          completedDate, (_) async { 
//          final now = DateTime.now();
//          await FirebaseFirestore.instance .collection('tasks') .doc(task['task_id']) .update({ 'completed_date': Timestamp.fromDate(now), 'status': 'Completed', 'progress_percent': '100', }); 
//           await _storeReportData( userId: widget.currentUserId,
//            progressPercent: '100', 
//            taskId: task['task_id'], 
//            startDate: startDate, 
//            completedDate: now, );
//            _refreshData();
//            }), 
//            if (startDate != null) 
//            const SizedBox(height: 12), 
//            // 🔹 Progress Dropdown 
//            if (startDate != null) 
//            Row( 
//             mainAxisAlignment: MainAxisAlignment.spaceBetween, 
//             children: [
//             const Text("Progress %:"), 
//            Container( 
//             width: 100, 
//             padding: const EdgeInsets.symmetric(horizontal: 8), 
//             decoration: BoxDecoration( 
//             gradient: const LinearGradient( 
//             colors: [Colors.orange, Colors.deepOrangeAccent], ), 
//             borderRadius: BorderRadius.circular(8), ), 
//            child: DropdownButton<String>( 
//             dropdownColor: Colors.orange.shade200,
//              value: progress,
//            underline: const SizedBox(), 
//            isExpanded: true,
//           items: validProgressValues .map((val) => 
//          DropdownMenuItem( value: val, child: Text("$val%"), )) .toList(), 
//         onChanged: (newValue) async {
//        if (newValue != null) {
//        final now = DateTime.now(); Map<String, dynamic> 
//        updateData = { 'progress_percent': newValue };
//       DateTime? currentCompleted; 
//       if (newValue == '100' && completedDate == null) {
//      updateData['completed_date'] = Timestamp.fromDate(now); 
//       updateData['status'] = 'Completed'; currentCompleted = now;
//      }
//     await FirebaseFirestore.instance .collection('tasks') .doc(task['task_id']) .update(updateData);
//     final taskSnapshot = await FirebaseFirestore.instance .collection('tasks') .doc(task['task_id']) .get(); 
//     final taskData = taskSnapshot.data() as Map<String, dynamic>?;
//     DateTime? currentStart = (taskData?['start_date'] as Timestamp?)?.toDate(); 
//     await _storeReportData( userId: widget.currentUserId, progressPercent: newValue, taskId: task['task_id'],
//      startDate: currentStart, completedDate: currentCompleted ?? completedDate, );
//     _refreshData(); 
//        }
//         }
//            )
//            )
//             ]
//            )
//          ]
//         )
//        )
//       )
//   );  
//  }
//    );
//  }


//  Widget _gradientButton( String label, DateTime? currentDate, Function(DateTime) onPicked)
//  {
//      return InkWell(
//       onTap: () => _selectDate(context, currentDate, onPicked), 
//       child: Container( 
//       padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16), 
//       decoration: _gradientBoxDecoration(),
//       child: Text(label, 
//       style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//       ),
//      );
//  }                                                                                                                                                                                                                                                                                                                                          
//       String _formatDate(DateTime date) => "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";
//      Future<List<String>> _getDistinctValues( String collection, String field) async {
//     final snapshot = await FirebaseFirestore.instance.collection(collection).get();
//      return snapshot.docs .map((doc) => (doc.data() as Map<String, dynamic>)[field]?.toString()) .whereType<String>() .toSet() .toList(); 
//      } 
//     Future<List<String>> _getDistinctAssignedByNames() async { 
//      final snapshot = await FirebaseFirestore.instance.collection('tasks').get();
//      List<String> names = []; for (var doc in snapshot.docs)
//       {                                                                                                                                                                                                                                                                                                                                                        
//        final assignedByRef = (doc.data() as Map<String, dynamic>)['assigned_by'] as DocumentReference?; 
//         if (assignedByRef != null) 
//         {
//          final userSnapshot = await assignedByRef.get(); 
//          final data = userSnapshot.data() as Map<String, dynamic>?; 
//          final name = data?['user_name']; 
//           if (name != null) names.add(name); 
//         }
//       }                                                                                                                                                                                                                                                                                                                                                   
//            return names.toSet().toList();
//     }                                                                                                                                                                                                                                                                                                                                                     
//     // 🔹 Store report data 
   
// Future<void> _storeReportData({
//   required String userId,
//   required String progressPercent,
//   required String taskId,
//   DateTime? startDate,
//   DateTime? completedDate,
// }) async {
//   try {
//     if (userId.isEmpty || taskId.isEmpty) {
//       debugPrint("❌ Missing userId or taskId in _storeReportData()");
//       return;
//     }

//     final reportsRef = FirebaseFirestore.instance.collection('reports');

//     // 🔹 Fetch actual task dates if not provided
//     final taskSnapshot = await FirebaseFirestore.instance
//         .collection('tasks')
//         .doc(taskId)
//         .get();

//     final taskData = taskSnapshot.data() as Map<String, dynamic>?;

//     DateTime? actualStartDate =
//         startDate ?? (taskData?['start_date'] as Timestamp?)?.toDate();
//     DateTime? actualCompletedDate =
//         completedDate ?? (taskData?['completed_date'] as Timestamp?)?.toDate();

//     // 🔹 Default average completion data
//     int avgCompletionMinutes = 0;
//     Timestamp? avgCompletionTimestamp;

//     // 🔹 Calculate average completion time if both dates exist
//     if (actualStartDate != null && actualCompletedDate != null) {
//       final diff = actualCompletedDate.difference(actualStartDate);
//       avgCompletionMinutes = diff.inMinutes;
//       avgCompletionTimestamp = Timestamp.fromDate(DateTime(0).add(diff));
//     }

//     // 🔹 Add report data to Firestore
//     await reportsRef.add({
//       'report_id': const Uuid().v4(),
//       'user_ref': FirebaseFirestore.instance.doc('users/$userId'),
//       'task_id': taskId,
//       'progress_percent': progressPercent,
//       'tasks_completed': actualCompletedDate != null ? '1' : '0',
//       'tasks_pending': actualCompletedDate == null ? '1' : '0',
//       'avg_completion_minutes': avgCompletionMinutes,
//       'avg_completion_time': avgCompletionTimestamp,
//       'start_date': actualStartDate != null
//           ? Timestamp.fromDate(actualStartDate)
//           : null,
//       'completed_date': actualCompletedDate != null
//           ? Timestamp.fromDate(actualCompletedDate)
//           : null,
//       'date': Timestamp.now(),
//     });

//     if (kDebugMode) {
//       debugPrint(
//         "✅ Report logged for task: $taskId\n"
//         "User: $userId | Progress: $progressPercent%\n"
//         "Start: $actualStartDate | Completed: $actualCompletedDate\n"
//         "Avg Time: ${avgCompletionMinutes} min | Timestamp: $avgCompletionTimestamp",
//       );
//     }
//   } catch (e, stack) {
//     if (kDebugMode) {
//       debugPrint("❌ Error storing report: $e\n$stack");
//     }
//   }
// }
//     }          
//

    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedStatus = 'Pending';
  DateTime? _startFilterDate;
  DateTime? _endFilterDate;
  String? _assignedByFilter;
  String? _deptFilter;
  String? _priorityFilter;
  String? _titleFilter;

  final List<String> priorities = ['High', 'Medium', 'Low'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  Future<void> _refreshData({bool clearFilters = false}) async {
    if (clearFilters) {
      _startFilterDate = null;
      _endFilterDate = null;
      _priorityFilter = null;
      _deptFilter = null;
      _titleFilter = null;
      _assignedByFilter = null;
    }
    setState(() {});
  }

  /// Returns a stream of all tasks with status==[status]
  /// We will filter assigned_to for current user client-side to avoid mixing
  /// string ids and DocumentReference values in Firestore queries.
  Stream<QuerySnapshot> _getTasksByStatusRaw(String status) {
    return FirebaseFirestore.instance
        .collection('tasks')
        .where('status', isEqualTo: status)
        .snapshots();
  }

  bool _isTaskAssignedToCurrentUser(Map<String, dynamic> data) {
    final assignedTo = data['assigned_to'];
    final userId = widget.currentUserId;
    // assigned_to can be:
    // - a String userId
    // - a DocumentReference to users/{userId}
    // - a List containing any of the above (array)
    // We'll handle these cases defensively.

    if (assignedTo == null) return false;

    if (assignedTo is String) {
      return assignedTo == userId;
    } else if (assignedTo is DocumentReference) {
      return assignedTo.path == 'users/$userId' ||
          assignedTo.id == userId; // safer check
    } else if (assignedTo is List) {
      for (var item in assignedTo) {
        if (item is String && item == userId) return true;
        if (item is DocumentReference &&
            (item.path == 'users/$userId' || item.id == userId)) return true;
      }
    }
    return false;
  }

  Future<String> _getAssignedByName(DocumentReference? assignedByRef) async {
    try {
      if (assignedByRef == null) return 'Unknown';
      final snapshot = await assignedByRef.get();
      final data = snapshot.data() as Map<String, dynamic>?;
      return (data?['user_name'] as String?) ?? 'Unknown';
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching assignedByName: $e');
      return 'Unknown';
    }
  }

  Future<String> _getDeptName(DocumentReference? deptRef) async {
    try {
      if (deptRef == null) return 'Unknown';
      final snapshot = await deptRef.get();
      final data = snapshot.data() as Map<String, dynamic>?;
      return (data?['dept_name'] as String?) ?? 'Unknown';
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching deptName: $e');
      return 'Unknown';
    }
  }

  Future<void> _selectDate(BuildContext context, DateTime? initialDate,
      Function(DateTime) onSelected) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) onSelected(picked);
  }

  void _openFilterDialog() async {
    DateTime? tempStart = _startFilterDate;
    DateTime? tempEnd = _endFilterDate;
    String? tempPriority = _priorityFilter;
    String? tempDept = _deptFilter;
    String? tempAssignedBy = _assignedByFilter;
    String? tempTitle = _titleFilter;

    final deptList = await _getDistinctValues('tasks', 'dept_name');
    final titleList = await _getDistinctValues('tasks', 'title');
    final assignedByList = await _getDistinctAssignedByNames();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Filter Tasks"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String?>(
                value: tempTitle,
                decoration: const InputDecoration(labelText: "Title"),
                items: [
                  const DropdownMenuItem(value: null, child: Text("All")),
                  ...titleList
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                ],
                onChanged: (val) => tempTitle = val,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                value: tempDept,
                decoration: const InputDecoration(labelText: "Department"),
                items: [
                  const DropdownMenuItem(value: null, child: Text("All")),
                  ...deptList
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                ],
                onChanged: (val) => tempDept = val,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                value: tempAssignedBy,
                decoration: const InputDecoration(labelText: "Assigned By"),
                items: [
                  const DropdownMenuItem(value: null, child: Text("All")),
                  ...assignedByList
                      .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                      .toList(),
                ],
                onChanged: (val) => tempAssignedBy = val,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                decoration: const InputDecoration(labelText: "Priority"),
                value: tempPriority,
                items: [
                  const DropdownMenuItem(value: null, child: Text("All")),
                  ...priorities
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                ],
                onChanged: (val) => tempPriority = val,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () =>
                          _selectDate(context, tempStart, (picked) {
                        setState(() => tempStart = picked);
                      }),
                      child: Text(tempStart == null
                          ? "Start Date"
                          : "${tempStart!.day}/${tempStart!.month}/${tempStart!.year}"),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () => _selectDate(context, tempEnd, (picked) {
                        setState(() => tempEnd = picked);
                      }),
                      child: Text(tempEnd == null
                          ? "End Date"
                          : "${tempEnd!.day}/${tempEnd!.month}/${tempEnd!.year}"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _startFilterDate = tempStart;
                _endFilterDate = tempEnd;
                _priorityFilter = tempPriority;
                _deptFilter = tempDept;
                _titleFilter = tempTitle;
                _assignedByFilter = tempAssignedBy;
              });
              Navigator.pop(context);
            },
            child: const Text("Apply"),
          ),
          TextButton(
            onPressed: () {
              _refreshData(clearFilters: true);
              Navigator.pop(context);
            },
            child: const Text("Clear"),
          ),
        ],
      ),
    );
  }

/// Returns a stream of unread notification count for the current user
Stream<int> _unreadNotificationCount() {
  final userRef = FirebaseFirestore.instance.doc('users/${widget.currentUserId}');
  return FirebaseFirestore.instance
      .collection('notifications')
      .where('user_ref', isEqualTo: userRef)
      .where('is_read', isEqualTo: false)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
}


 Future<List<Map<String, dynamic>>> _fetchUnreadNotifications() async {
  final snapshot = await FirebaseFirestore.instance
      .collection('notifications')
      .where('user_id', isEqualTo: widget.currentUserId)
      .where('read', isEqualTo: false)
      .orderBy('created_at', descending: true)
      .get();

  return snapshot.docs
      .map((doc) => {
            'doc_id': doc.id,
            ...doc.data(),
          })
      .toList();
}




  void _showNotifications() async {
    final notifications = await _fetchUnreadNotifications();
    if (notifications.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No new notifications")));
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Notifications"),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notif = notifications[index];
                  return ListTile(
                    title: Text(notif['title'] ?? ''),
                    subtitle: Text(notif['message'] ?? ''),
                    trailing: Text(
                      notif['timestamp'] != null
                          ? (notif['timestamp'] as Timestamp)
                              .toDate()
                              .toLocal()
                              .toString()
                          : '',
                      style: const TextStyle(fontSize: 10),
                    ),
                    onTap: () async {
  await FirebaseFirestore.instance
      .collection('notifications')
      .doc(notif['doc_id'])
      .update({'read': true});

  Navigator.pop(context);
  _refreshData();
},

                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          ),
    );
  }

  /// Utility: fetch distinct string values from documents in a collection for a field
  Future<List<String>> _getDistinctValues(
      String collection, String field) async {
    final snapshot = await FirebaseFirestore.instance.collection(collection).get();
    return snapshot.docs
        .map((doc) => (doc.data() as Map<String, dynamic>)[field]?.toString())
        .whereType<String>()
        .toSet()
        .toList();
  }

  Future<List<String>> _getDistinctAssignedByNames() async {
    final snapshot = await FirebaseFirestore.instance.collection('tasks').get();
    List<String> names = [];
    for (var doc in snapshot.docs) {
      final assignedByRef =
          (doc.data() as Map<String, dynamic>)['assigned_by'] as DocumentReference?;
      if (assignedByRef != null) {
        final userSnapshot = await assignedByRef.get();
        final data = userSnapshot.data() as Map<String, dynamic>?;
        final name = data?['user_name'];
        if (name != null) names.add(name);
      }
    }
    return names.toSet().toList();
  }

  /// Store report data similar to your original implementation, defensively.
  Future<void> _storeReportData({
    required String userId,
    required String progressPercent,
    required String taskId,
    DateTime? startDate,
    DateTime? completedDate,
  }) async {
    try {
      if (userId.isEmpty || taskId.isEmpty) {
        debugPrint("❌ Missing userId or taskId in _storeReportData()");
        return;
      }

      final reportsRef = FirebaseFirestore.instance.collection('reports');

      // Fetch actual task dates if not provided
      final taskSnapshot =
          await FirebaseFirestore.instance.collection('tasks').doc(taskId).get();

      final taskData = taskSnapshot.data() as Map<String, dynamic>?;

      DateTime? actualStartDate =
          startDate ?? (taskData?['start_date'] as Timestamp?)?.toDate();
      DateTime? actualCompletedDate =
          completedDate ?? (taskData?['completed_date'] as Timestamp?)?.toDate();

      // Default average completion data
      int avgCompletionMinutes = 0;
      Timestamp? avgCompletionTimestamp;

      // Calculate average completion time if both dates exist
      if (actualStartDate != null && actualCompletedDate != null) {
        final diff = actualCompletedDate.difference(actualStartDate);
        avgCompletionMinutes = diff.inMinutes;
        avgCompletionTimestamp = Timestamp.fromDate(DateTime(0).add(diff));
      }

      // Add report data to Firestore
      await reportsRef.add({
        'report_id': const Uuid().v4(),
        'user_ref': FirebaseFirestore.instance.doc('users/$userId'),
        'task_id': taskId,
        'progress_percent': progressPercent,
        'tasks_completed': actualCompletedDate != null ? '1' : '0',
        'tasks_pending': actualCompletedDate == null ? '1' : '0',
        'avg_completion_minutes': avgCompletionMinutes,
        'avg_completion_time': avgCompletionTimestamp,
        'start_date': actualStartDate != null
            ? Timestamp.fromDate(actualStartDate)
            : null,
        'completed_date': actualCompletedDate != null
            ? Timestamp.fromDate(actualCompletedDate)
            : null,
        'date': Timestamp.now(),
      });

      if (kDebugMode) {
        debugPrint(
          "✅ Report logged for task: $taskId\n"
          "User: $userId | Progress: $progressPercent%\n"
          "Start: $actualStartDate | Completed: $actualCompletedDate\n"
          "Avg Time: ${avgCompletionMinutes} min | Timestamp: $avgCompletionTimestamp",
        );
      }
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint("❌ Error storing report: $e\n$stack");
      }
    }
  }

  /// Format date to DD-MM-YYYY
  String _formatDate(DateTime date) =>
      "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";

  /// Top status cards stream to compute counts for Pending / In Progress / Completed
  Stream<Map<String, int>> _statusCountsStream() {
    // Listen to tasks collection and compute counts client-side for tasks assigned to current user
    return FirebaseFirestore.instance.collection('tasks').snapshots().map((snap) {
      int pending = 0, inProgress = 0, completed = 0;
      for (var doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (!_isTaskAssignedToCurrentUser(data)) continue;
        final status = (data['status'] ?? '').toString().toLowerCase();
        if (status.contains('pending')) pending++;
        else if (status.contains('in progress') || status.contains('inprogress')) {
          inProgress++;
        } else if (status.contains('complete') || status.contains('completed')) {
          completed++;
        }
      }
      return {'Pending': pending, 'In Progress': inProgress, 'Completed': completed};
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    return Scaffold(
      body: CommonScaffold(
        title: "",
        role: widget.currentUserRole,
        body: Column(
          children: [
            // ---------- TOP ROW: Title + Actions ----------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final isMobileLocal = width < 600;

                  return Row(
                    mainAxisAlignment: isMobileLocal
                        ? MainAxisAlignment.spaceBetween
                        : MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Title
                      Expanded(
                        child: Align(
                          alignment:
                              isMobileLocal ? Alignment.centerLeft : Alignment.center,
                          child: ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                Color(0xFF34D0C6),
                                Color(0xFF22A4E0),
                                Color(0xFF1565C0),
                              ],
                            ).createShader(
                                Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                            child: Text(
                              "Task",
                              style: TextStyle(
                                fontSize: isMobileLocal ? 22 : 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white, // overridden by gradient
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Action Icons
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                        StreamBuilder<int>(
    stream: _unreadNotificationCount(),
    builder: (context, snapshot) {
      final count = snapshot.data ?? 0;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NotificationHistoryScreen(
                    currentUserId: widget.currentUserId, 
                    currentUserRole: widget.currentUserRole,
                  ),
                ),
              );
            },
          ),
          if (count > 0)
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      );
    },
  ),

                           const SizedBox(width: 12),
                          _iconButton(Icons.filter_list, _openFilterDialog),
                          const SizedBox(width: 12),
                          _iconButton(Icons.refresh, () => _refreshData(clearFilters: true)),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),

            // ---------- STATUS CARDS (counts) ----------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SizedBox(
                height: 90,
                child: StreamBuilder<Map<String, int>>(
                  stream: _statusCountsStream(),
                  builder: (context, snap) {
                    final counts = snap.data ?? {'Pending': 0, 'In Progress': 0, 'Completed': 0};
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _statusCountCard('Pending', counts['Pending'] ?? 0, Colors.orange),
                        _statusCountCard('In Progress', counts['In Progress'] ?? 0, Colors.blue),
                        _statusCountCard('Completed', counts['Completed'] ?? 0, Colors.green),
                      ],
                    );
                  },
                ),
              ),
            ),

            // ---------- TAB BAR ----------
            // Container(
            //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            //   child: TabBar(
            //     controller: _tabController,
            //     indicator: BoxDecoration(
            //       color: _getTabColor(selectedStatus),
            //       borderRadius: BorderRadius.circular(8),
            //     ),
            //     labelColor: Colors.white,
            //     unselectedLabelColor: Colors.black87,
            //     tabs: const [
            //       Tab(child: Text(" Pending ")),
            //       Tab(child: Text(" In Progress ")),
            //       Tab(child: Text(" Complete ")),
            //     ],
            //     onTap: (index) {
            //       setState(() {
            //         selectedStatus = index == 0
            //             ? 'Pending'
            //             : index == 1
            //                 ? 'In Progress'
            //                 : 'Completed';
            //       });
            //     },
            //   ),
            // ),

            // ---------- TASK LIST ----------
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getTasksByStatusRaw(selectedStatus),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No tasks found."));
                  }

                  // Filter for tasks assigned to current user client-side
                  final allDocs = snapshot.data!.docs;
                  final assignedDocs = allDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return _isTaskAssignedToCurrentUser(data);
                  }).toList();

                  // Apply additional filters (date range, dept, priority, title, assignedBy)
                  final filteredDocs = assignedDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    // date filters
                    final dueTimestamp = data['due_date'] as Timestamp?;
                    final dueDate = dueTimestamp?.toDate();
                    if (_startFilterDate != null) {
                      if (dueDate == null ||
                          dueDate.isBefore(DateTime(
                              _startFilterDate!.year,
                              _startFilterDate!.month,
                              _startFilterDate!.day))) return false;
                    }
                    if (_endFilterDate != null) {
                      if (dueDate == null ||
                          dueDate.isAfter(DateTime(
                              _endFilterDate!.year,
                              _endFilterDate!.month,
                              _endFilterDate!.day).add(const Duration(days: 1)))) return false;
                    }
                    // dept
                    if (_deptFilter != null && _deptFilter!.isNotEmpty) {
                      final deptName = data['dept_name']?.toString() ?? '';
                      if (deptName != _deptFilter) return false;
                    }
                    // priority
                    if (_priorityFilter != null && _priorityFilter!.isNotEmpty) {
                      final p = data['priority']?.toString() ?? '';
                      if (p != _priorityFilter) return false;
                    }
                    // title
                    if (_titleFilter != null && _titleFilter!.isNotEmpty) {
                      final t = data['title']?.toString() ?? '';
                      if (t != _titleFilter) return false;
                    }
                    // assignedBy
                    if (_assignedByFilter != null && _assignedByFilter!.isNotEmpty) {
                      final assignedByName = data['assigned_by_name']?.toString() ?? '';
                      if (assignedByName != _assignedByFilter) return false;
                    }

                    return true;
                  }).toList();

                  final tasks = filteredDocs;
                  int crossAxisCount = isMobile ? 1 : isTablet ? 2 : 3;

                  return GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: isMobile ? 1.2 : isTablet ? 1.4 : 1.6,
                    ),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final data = tasks[index].data() as Map<String, dynamic>;
                      // Ensure doc has task_id; if not, fall back to doc.id
                      data['task_id'] ??= tasks[index].id;
                      return SizedBox(
                        width: isMobile ? double.infinity : 380,
                        height: 280,
                        child: _buildTaskCard(data),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 40,
      height: 40,
      decoration: _gradientBoxDecoration(),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }

  BoxDecoration _gradientBoxDecoration() => BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF34D0C6),
            Color(0xFF22A4E0),
            Color(0xFF1565C0),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      );

  // Widget _floatingAddButton(BuildContext context) => Container(
  //       decoration: _gradientBoxDecoration(),
  //       child: FloatingActionButton(
  //         elevation: 0,
  //         backgroundColor: Colors.transparent,
  //         child: const Icon(Icons.add, color: Colors.white, size: 30),
  //         onPressed: () {
  //           Navigator.push(
  //             context,
  //             MaterialPageRoute(
  //               builder: (_) => TaskAllocationScreen(
  //                 currentUserId: FirebaseAuth.instance.currentUser?.uid ?? '',
  //                 currentUserRole: widget.currentUserRole,
  //               ),
  //             ),
  //           );
  //         },
  //       ),
  //     );

  Color _getTabColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'In Progress':
        return Colors.blue;
      case 'Completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _statusCountCard(String label, int count, Color color) {
    return Expanded(
      child: InkWell(
        onTap: () {
          // set tab and status filter
          setState(() {
            selectedStatus = label;
            _tabController.index = label == 'Pending'
                ? 0
                : label == 'In Progress'
                    ? 1
                    : 2;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.95),
                color.withOpacity(0.65),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(count.toString(),
                  style: const TextStyle(
                      color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final status = (task['status'] ?? 'Pending').toString();
    String progress = (task['progress_percent'] ?? '0').toString();
    final dueDate = (task['due_date'] as Timestamp?)?.toDate();
    final startDate = (task['start_date'] as Timestamp?)?.toDate();
    final completedDate = (task['completed_date'] as Timestamp?)?.toDate();
    final assignedByRef = task['assigned_by'] as DocumentReference?;
    final deptRef = task['department_id'] as DocumentReference?;
    final priority = task['priority'] ?? 'N/A';

    // validate progress values (0,10,20,...100)
    final validProgressValues = List.generate(11, (i) => (i * 10).toString());
    if (!validProgressValues.contains(progress)) progress = '0';

    final isOverdue = dueDate != null &&
        completedDate == null &&
        DateTime.now().isAfter(DateTime(dueDate.year, dueDate.month, dueDate.day)
            .add(const Duration(days: 1)));

    // Fetch assignedByName and deptName asynchronously, then render
    return FutureBuilder<Map<String, String>>(
      future: () async {
        String assignedByName = 'Unknown';
        String deptName = 'Unknown';
        // try to load assigned_by_name quickly from task data if present
        if (task['assigned_by_name'] != null &&
            (task['assigned_by_name'] as String).isNotEmpty) {
          assignedByName = task['assigned_by_name'] as String;
        } else {
          assignedByName = await _getAssignedByName(assignedByRef);
        }

        // dept name
        if (task['dept_name'] != null && (task['dept_name'] as String).isNotEmpty) {
          deptName = task['dept_name'] as String;
        } else {
          deptName = await _getDeptName(deptRef);
        }

        return {'assignedBy': assignedByName, 'department': deptName};
      }(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final assignedByName = snapshot.data!['assignedBy'] ?? 'Unknown';
        final deptName = snapshot.data!['department'] ?? 'Unknown';
        final double progressValue =
            (int.tryParse(progress) ?? 0).clamp(0, 100) / 100.0;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + status badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          task['title'] ?? 'No Title',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isOverdue ? Colors.red.shade400 : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isOverdue ? 'Overdue' : status,
                          style: TextStyle(
                              color: isOverdue ? Colors.white : Colors.black87),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),
                  Text(task['description'] ?? 'No Description',
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 10),

                  // Department & Priority & AssignedBy
                  Wrap(
                    runSpacing: 6,
                    spacing: 12,
                    children: [
                      Text("Department: $deptName"),
                      Text(
                        "Priority: $priority",
                        style: TextStyle(
                          color: priority == 'High'
                              ? Colors.red
                              : priority == 'Medium'
                                  ? Colors.orange
                                  : Colors.green,
                        ),
                      ),
                      Text("Assigned By: $assignedByName",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Dates
                  Text(
                    "Due Date: ${dueDate != null ? _formatDate(dueDate) : '-'}",
                    style: TextStyle(color: isOverdue ? Colors.red : Colors.black),
                  ),
                  const SizedBox(height: 6),
                  Text("Start Date: ${startDate != null ? _formatDate(startDate) : '-'}"),
                  const SizedBox(height: 6),
                  Text(
                      "Completion Date: ${completedDate != null ? _formatDate(completedDate) : '-'}"),
                  const SizedBox(height: 12),

                  // Action buttons (Set Start / Set Completed)
                  Row(
                    children: [
                      if (startDate == null)
                        Expanded(
                          child: _gradientActionButton("Set Start Date", () async {
                            final now = DateTime.now();
                            await FirebaseFirestore.instance
                                .collection('tasks')
                                .doc(task['task_id'])
                                .update({
                              'start_date': Timestamp.fromDate(now),
                              'status': 'In Progress',
                              // keep progress at 0 initially
                              'progress_percent': '0',
                            });
                            await _storeReportData(
                              userId: widget.currentUserId,
                              progressPercent: '0',
                              taskId: task['task_id'],
                              startDate: now,
                            );
                            _refreshData();
                          }),
                        ),

                      if (startDate != null && completedDate == null)
                        Expanded(
                          child: _gradientActionButton("Set Completion Date", () async {
                            final now = DateTime.now();
                            await FirebaseFirestore.instance
                                .collection('tasks')
                                .doc(task['task_id'])
                                .update({
                              'completed_date': Timestamp.fromDate(now),
                              'status': 'Completed',
                              'progress_percent': '100',
                            });
                            await _storeReportData(
                              userId: widget.currentUserId,
                              progressPercent: '100',
                              taskId: task['task_id'],
                              startDate: startDate,
                              completedDate: now,
                            );
                            _refreshData();
                          }),
                        ),
                    ],
                  ),

                  if (startDate != null) const SizedBox(height: 12),

                  // Progress bar + Dropdown
                  if (startDate != null) ...[
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Progress"),
                              const SizedBox(height: 6),
                              LinearProgressIndicator(
                                value: progressValue,
                                minHeight: 8,
                              ),
                              const SizedBox(height: 6),
                              Text("${(progressValue * 100).round()}%"),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [Colors.orange, Colors.deepOrangeAccent]),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButton<String>(
                              dropdownColor: Colors.orange.shade200,
                              value: progress,
                              underline: const SizedBox(),
                              isExpanded: true,
                              items: validProgressValues
                                  .map((val) =>
                                      DropdownMenuItem(value: val, child: Text("$val%")))
                                  .toList(),
                            onChanged: (newValue) async {
                                if (newValue != null) {
                                  final now = DateTime.now();

                                  Map<String, dynamic> updateData = {
                                    'progress_percent': newValue,
                                    'updated_at': Timestamp.now(), // ✅ ADDED
                                  };

                                  DateTime? currentCompleted;

                                  if (newValue == '100' &&
                                      completedDate == null) {
                                    updateData.addAll({
                                      'completed_date': Timestamp.fromDate(now),
                                      'status': 'Completed',
                                      'updated_at': Timestamp.now(), // ✅ ADDED
                                    });
                                    currentCompleted = now;
                                  } else if (newValue != '100') {
                                    if ((task['status'] ?? '')
                                        .toString()
                                        .toLowerCase()
                                        .contains('completed')) {
                                      updateData.addAll({
                                        'status': 'In Progress',
                                        'updated_at':
                                            Timestamp.now(), // ✅ ADDED
                                      });
                                    }
                                  }

                                  await FirebaseFirestore.instance
                                      .collection('tasks')
                                      .doc(task['task_id'])
                                      .update(updateData);

                                  final taskSnapshot =
                                      await FirebaseFirestore.instance
                                          .collection('tasks')
                                          .doc(task['task_id'])
                                          .get();

                                  final taskData =
                                      taskSnapshot.data()
                                          as Map<String, dynamic>?;

                                  DateTime? currentStart =
                                      (taskData?['start_date'] as Timestamp?)
                                          ?.toDate();

                                  await _storeReportData(
                                    userId: widget.currentUserId,
                                    progressPercent: newValue,
                                    taskId: task['task_id'],
                                    startDate: currentStart,
                                    completedDate:
                                        currentCompleted ?? completedDate,
                                  );

                                  _refreshData();
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _gradientActionButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: _gradientBoxDecoration().copyWith(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(label,
              style:
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
