// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';

// class AttendanceScreen extends StatefulWidget {
//   final String currentUserId;
//   final String currentUserRole;

//   const AttendanceScreen({
//     super.key,
//     required this.currentUserId,
//     required this.currentUserRole,
//   });

//   @override
//   State<AttendanceScreen> createState() => _AttendanceScreenState();
// }

// class _AttendanceScreenState extends State<AttendanceScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   bool isLoading = false;

//   Map<String, dynamic>? attendanceData;
//   String? userName;

//   String getGreeting() {
//     final hour = DateTime.now().hour;
//     if (hour < 12) return "Good Morning";
//     if (hour < 17) return "Good Afternoon";
//     return "Good Evening";
//   }

//   String getFormattedDate() {
//     final now = DateTime.now();
//     return DateFormat('EEEE, dd MMMM yyyy').format(now);
//   }

//   @override
//   void initState() {
//     super.initState();
//     loadUserName();
//     loadAttendance();
//   }

//   /// 🔹 Load employee/intern name using user ID
//   Future<void> loadUserName() async {
//   try {
//     setState(() => isLoading = true);

//     DocumentSnapshot userDoc;
//     if (widget.currentUserRole.toLowerCase() == "employee") {
//       userDoc = await _firestore
//           .collection('employees')
//           .doc(widget.currentUserId)
//           .get();
//     } else {
//       userDoc = await _firestore
//           .collection('interns')
//           .doc(widget.currentUserId)
//           .get();
//     }

//     if (userDoc.exists) {
//       if (widget.currentUserRole.toLowerCase() == "employee") {
//         userName = userDoc.data().toString().contains('emp_name')
//             ? userDoc.get('emp_name')
//             : "User";
//       } else {
//         userName = userDoc.data().toString().contains('intern_name')
//             ? userDoc.get('intern_name')
//             : "User";
//       }
//     } else {
//       userName = "User";
//     }

//     setState(() {});
//   } catch (e) {
//     userName = "User";
//   } finally {
//     setState(() => isLoading = false);
//   }
// }


//   Future<void> loadAttendance() async {
//     setState(() => isLoading = true);
//     final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

//     final doc = await _firestore
//         .collection('attendance')
//         .doc(widget.currentUserId)
//         .collection('records')
//         .doc(dateKey)
//         .get();

//     if (doc.exists) {
//       attendanceData = doc.data();
//     } else {
//       attendanceData = {
//         "intime": null,
//         "lunchStart": null,
//         "lunchEnd": null,
//         "teaStart": null,
//         "teaEnd": null,
//         "outtime": null,
//         "status": "Absent",
//         "totalHours": null,
//         "date": dateKey,
//       };
//     }

//     setState(() => isLoading = false);
//   }

//   Future<void> markTime(String fieldName) async {
//     final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
//     final now = DateFormat('hh:mm a').format(DateTime.now());

//     if (attendanceData![fieldName] != null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("$fieldName already marked!")),
//       );
//       return;
//     }

//     setState(() => isLoading = true);

//     attendanceData![fieldName] = now;

//     // Mark present if intime is filled
//     if (fieldName == "intime") {
//       attendanceData!["status"] = "Present";
//     }

//     // If outtime is marked, calculate total hours
//     if (fieldName == "outtime" && attendanceData!["intime"] != null) {
//       attendanceData!["totalHours"] =
//           _calculateTotalHours(attendanceData!["intime"], now);
//     }

//     await _firestore
//         .collection('attendance')
//         .doc(widget.currentUserId)
//         .collection('records')
//         .doc(dateKey)
//         .set(attendanceData!);

//     setState(() => isLoading = false);
//   }

//   String _calculateTotalHours(String inTime, String outTime) {
//     try {
//       DateFormat format = DateFormat('hh:mm a');
//       DateTime inDateTime = format.parse(inTime);
//       DateTime outDateTime = format.parse(outTime);

//       // Handle cases where out time is past midnight
//       if (outDateTime.isBefore(inDateTime)) {
//         outDateTime = outDateTime.add(const Duration(days: 1));
//       }

//       Duration diff = outDateTime.difference(inDateTime);
//       int hours = diff.inHours;
//       int minutes = diff.inMinutes.remainder(60);

//       return "${hours}h ${minutes}m";
//     } catch (e) {
//       return "N/A";
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final greeting = getGreeting();
//     final date = getFormattedDate();

//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: PreferredSize(
//         preferredSize: const Size.fromHeight(65),
//         child: AppBar(
//           automaticallyImplyLeading: false,
//           flexibleSpace: Container(
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [Color(0xFF42A5F5), Color(0xFF1565C0)],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//             ),
//           ),
//           elevation: 0,
//           titleSpacing: 0,
//           title: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Row(
//                 children: [
//                   IconButton(
//                     icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
//                     onPressed: () => Navigator.pop(context),
//                   ),
                  
//                 ],
//               ),
//               Padding(
//                 padding: const EdgeInsets.only(right: 12.0),
//                 child:CircleAvatar(
//                       backgroundColor: Colors.white,
//                       backgroundImage: AssetImage('assets/logo.png')),
//               ),
//             ],
//           ),
//         ),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : attendanceData == null
//               ? const Center(child: Text("Loading attendance data..."))
//               : SingleChildScrollView(
//                   padding: const EdgeInsets.all(16),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         "$greeting, ${userName ?? 'User'}",
//                         style: const TextStyle(
//                             fontSize: 22, fontWeight: FontWeight.bold),
//                       ),
//                       const SizedBox(height: 6),
//                       Text(
//                         date,
//                         style: const TextStyle(
//                             fontSize: 16, color: Colors.black54),
//                       ),
//                       const SizedBox(height: 20),
//                       _buildAttendanceRow("In Time", "intime"),
//                       _buildAttendanceRow("Lunch Start", "lunchStart"),
//                       _buildAttendanceRow("Lunch End", "lunchEnd"),
//                       _buildAttendanceRow("Tea Start", "teaStart"),
//                       _buildAttendanceRow("Tea End", "teaEnd"),
//                       _buildAttendanceRow("Out Time", "outtime"),
//                       const SizedBox(height: 20),
//                       Center(
//                         child: Chip(
//                           backgroundColor:
//                               attendanceData!["status"] == "Present"
//                                   ? Colors.green
//                                   : Colors.red,
//                           label: Text(
//                             attendanceData!["status"] ?? "Absent",
//                             style: const TextStyle(color: Colors.white),
//                           ),
//                         ),
//                       ),
//                       if (attendanceData!["totalHours"] != null)
//                         Padding(
//                           padding: const EdgeInsets.only(top: 12),
//                           child: Center(
//                             child: Text(
//                               "Total Hours Worked: ${attendanceData!["totalHours"]}",
//                               style: const TextStyle(
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.w600,
//                                   color: Colors.black87),
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//     );
//   }

//   Widget _buildAttendanceRow(String label, String fieldName) {
//     final value = attendanceData?[fieldName];
//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 8),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       elevation: 3,
//       child: ListTile(
//         title: Text(label),
//         trailing: value == null
//             ? ElevatedButton(
//                 onPressed: () => markTime(fieldName),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF22A4E0),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//                 child: const Text("Mark",
//                     style: TextStyle(color: Colors.white)),
//               )
//             : Text(
//                 value,
//                 style: const TextStyle(
//                     color: Colors.black87, fontWeight: FontWeight.bold),
//               ),
//       ),
//     );
//   }
// }


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AttendanceScreen extends StatefulWidget {
  final String currentUserId;
  final String currentUserRole;

  const AttendanceScreen({
    super.key,
    required this.currentUserId,
    required this.currentUserRole,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = false;

  Map<String, dynamic>? attendanceData;
  String? userName;

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  String getFormattedDate() {
    final now = DateTime.now();
    return DateFormat('EEEE, dd MMMM yyyy').format(now);
  }

  @override
  void initState() {
    super.initState();
    loadUserName();
    loadAttendance();
  }

  Future<void> loadUserName() async {
    try {
      setState(() => isLoading = true);

      DocumentSnapshot userDoc;
      if (widget.currentUserRole.toLowerCase() == "employee") {
        userDoc = await _firestore
            .collection('employees')
            .doc(widget.currentUserId)
            .get();
      } else {
        userDoc = await _firestore
            .collection('interns')
            .doc(widget.currentUserId)
            .get();
      }

      if (userDoc.exists) {
        if (widget.currentUserRole.toLowerCase() == "employee") {
          userName = userDoc.data().toString().contains('emp_name')
              ? userDoc.get('emp_name')
              : "User";
        } else {
          userName = userDoc.data().toString().contains('intern_name')
              ? userDoc.get('intern_name')
              : "User";
        }
      } else {
        userName = "User";
      }

      setState(() {});
    } catch (e) {
      userName = "User";
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> loadAttendance() async {
    setState(() => isLoading = true);
    final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final doc = await _firestore
        .collection('attendance')
        .doc(widget.currentUserId)
        .collection('records')
        .doc(dateKey)
        .get();

    if (doc.exists) {
      attendanceData = doc.data();
    } else {
      attendanceData = {
        "intime": null,
        "lunchStart": null,
        "lunchEnd": null,
        "teaStart": null,
        "teaEnd": null,
        "outtime": null,
        "status": "Absent",
        "totalHours": null,
        "date": dateKey,
      };
    }

    setState(() => isLoading = false);
  }

  Future<void> markTime(String fieldName) async {
    final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final now = DateFormat('hh:mm a').format(DateTime.now());

    if (attendanceData![fieldName] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$fieldName already marked!")),
      );
      return;
    }

    setState(() => isLoading = true);

    attendanceData![fieldName] = now;

    if (fieldName == "intime") {
      attendanceData!["status"] = "Present";
    }

    if (fieldName == "outtime" && attendanceData!["intime"] != null) {
      attendanceData!["totalHours"] =
          _calculateTotalHours(attendanceData!["intime"], now);
    }

    await _firestore
        .collection('attendance')
        .doc(widget.currentUserId)
        .collection('records')
        .doc(dateKey)
        .set(attendanceData!);

    setState(() => isLoading = false);
  }

  String _calculateTotalHours(String inTime, String outTime) {
    try {
      DateFormat format = DateFormat('hh:mm a');
      DateTime inDateTime = format.parse(inTime);
      DateTime outDateTime = format.parse(outTime);

      if (outDateTime.isBefore(inDateTime)) {
        outDateTime = outDateTime.add(const Duration(days: 1));
      }

      Duration diff = outDateTime.difference(inDateTime);
      int hours = diff.inHours;
      int minutes = diff.inMinutes.remainder(60);

      return "${hours}h ${minutes}m";
    } catch (e) {
      return "N/A";
    }
  }

  @override
  Widget build(BuildContext context) {
    final greeting = getGreeting();
    final date = getFormattedDate();

    return Scaffold(
      backgroundColor: const Color(0xfff2f5f9),

      // APP BAR SAME — only UI improved
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
          elevation: 8,
          shadowColor: Colors.black26,
          titleSpacing: 0,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 12.0),
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
          : attendanceData == null
              ? const Center(child: Text("Loading attendance data..."))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$greeting, ${userName ?? 'User'}",
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D47A1),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        date,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),

                      const SizedBox(height: 25),

                      _buildAttendanceRow("In Time", "intime", Icons.login),
                      _buildAttendanceRow(
                          "Lunch Start", "lunchStart", Icons.lunch_dining),
                      _buildAttendanceRow(
                          "Lunch End", "lunchEnd", Icons.check_circle_outline),
                      _buildAttendanceRow("Tea Start", "teaStart",
                          Icons.free_breakfast_outlined),
                      _buildAttendanceRow("Tea End", "teaEnd",
                          Icons.free_breakfast_rounded),
                      _buildAttendanceRow("Out Time", "outtime",
                          Icons.logout_rounded),

                      const SizedBox(height: 20),

                      Center(
                        child: Chip(
                          padding: const EdgeInsets.symmetric(
                              vertical: 6, horizontal: 12),
                          backgroundColor:
                              attendanceData!["status"] == "Present"
                                  ? Colors.green
                                  : Colors.redAccent,
                          label: Text(
                            attendanceData!["status"] ?? "Absent",
                            style: const TextStyle(
                                color: Colors.white, fontSize: 15),
                          ),
                        ),
                      ),

                      if (attendanceData!["totalHours"] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Center(
                            child: Text(
                              "Total Hours Worked: ${attendanceData!["totalHours"]}",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  /// 🔹 BEAUTIFUL NEW CARD DESIGN
  Widget _buildAttendanceRow(String label, String fieldName, IconData icon) {
    final value = attendanceData?[fieldName];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: value == null
            ? LinearGradient(
                colors: [
                  Colors.white,
                  Colors.blue.shade50,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  Colors.green.shade50,
                  Colors.white,
                ],
              ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              value == null ? const Color(0xFF22A4E0) : Colors.green,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          label,
          style: const TextStyle(
              fontSize: 17, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        trailing: value == null
            ? ElevatedButton(
                onPressed: () => markTime(fieldName),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                ),
                child: const Text("Mark",
                    style: TextStyle(color: Colors.white, fontSize: 15)),
              )
            : Text(
                value,
                style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
      ),
    );
  }
}
