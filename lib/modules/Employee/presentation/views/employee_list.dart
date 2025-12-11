// import 'dart:ui';
// import 'package:intl/intl.dart';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:task_management_application/modules/Employee/presentation/views/employee_register.dart';
// import 'package:task_management_application/utils/common/appbar_drawer.dart';
// import 'package:task_management_application/utils/components/kdrt_colors.dart';

// class EmployeeListScreen extends StatefulWidget {
//   final String currentUserId;
//   final String currentUserRole;

//   const EmployeeListScreen({
//     super.key,
//     required this.currentUserId,
//     required this.currentUserRole,
//   });

//   @override
//   State<EmployeeListScreen> createState() => _EmployeeListScreenState();
// }

// class _EmployeeListScreenState extends State<EmployeeListScreen> {
//   final TextEditingController _filterController = TextEditingController();
//   List<DocumentSnapshot> _employees = [];
//   List<DocumentSnapshot> _filteredEmployees = [];
//   bool _isLoading = true;

//   final LinearGradient _gradient = const LinearGradient(
//     colors: [Color(0xFF34D0C6), Color(0xFF22A4E0), Color(0xFF1565C0)],
//     begin: Alignment.centerLeft,
//     end: Alignment.centerRight,
//   );

//   @override
//   void initState() {
//     super.initState();
//     fetchEmployees();
//   }

//   Future<void> fetchEmployees() async {
//     setState(() => _isLoading = true);
//     final snapshot =
//         await FirebaseFirestore.instance.collection('employees').get();
//     setState(() {
//       _employees = snapshot.docs;
//       _filteredEmployees = _employees;
//       _isLoading = false;
//     });
//   }

//   void filterEmployees(String query) {
//     setState(() {
//       if (query.isEmpty) {
//         _filteredEmployees = _employees;
//       } else {
//         _filteredEmployees = _employees.where((doc) {
//           final data = doc.data() as Map<String, dynamic>;
//           final name = data['emp_name']?.toString().toLowerCase() ?? '';
//           final email = data['emp_email']?.toString().toLowerCase() ?? '';
//           final phone = data['emp_phone']?.toString().toLowerCase() ?? '';
//           final designation =
//               data['emp_designation']?.toString().toLowerCase() ?? '';
//           return name.contains(query.toLowerCase()) ||
//               email.contains(query.toLowerCase()) ||
//               phone.contains(query.toLowerCase()) ||
//               designation.contains(query.toLowerCase());
//         }).toList();
//       }
//     });
//   }

//   Future<void> deleteEmployee(String empId) async {
//     await FirebaseFirestore.instance.collection('employees').doc(empId).delete();
//     fetchEmployees();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final bool isMobile = MediaQuery.of(context).size.width < 600;

//     return CommonScaffold(
//       title: "Employee List",
//       role: widget.currentUserRole,
//       // IMPORTANT: body contains the full page and the FAB is placed inside it via Stack
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Stack(
//               children: [
//                 // Main content
//                 Container(
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: [Colors.white, Colors.grey.shade100],
//                       begin: Alignment.topCenter,
//                       end: Alignment.bottomCenter,
//                     ),
//                   ),
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     children: [
//                       // 🔍 Filter and Refresh Row
//                       Row(
//                         children: [
//                           Expanded(
//                             child: TextField(
//                               controller: _filterController,
//                               onChanged: filterEmployees,
//                               decoration: InputDecoration(
//                                 prefixIcon: const Icon(Icons.search),
//                                 hintText: "Search by name, email, phone or designation",
//                                 filled: true,
//                                 fillColor: Colors.white,
//                                 contentPadding: const EdgeInsets.symmetric(
//                                     vertical: 12, horizontal: 12),
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                   borderSide: BorderSide.none,
//                                 ),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 10),
//                           // Refresh button with gradient background
//                           Container(
//                             decoration: BoxDecoration(
//                               gradient: _gradient,
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: IconButton(
//                               onPressed: fetchEmployees,
//                               icon: const Icon(Icons.refresh, color: Colors.white),
//                               tooltip: "Refresh",
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 20),

//                       // 📋 Employee Data Table
//                       Expanded(
//                         child: Container(
//                           decoration: BoxDecoration(
//                             color: Colors.white.withOpacity(0.95),
//                             borderRadius: BorderRadius.circular(12),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.grey.withOpacity(0.12),
//                                 blurRadius: 8,
//                                 offset: const Offset(0, 4),
//                               )
//                             ],
//                           ),
//                           child: ScrollConfiguration(
//       behavior: ScrollConfiguration.of(context).copyWith(
//         dragDevices: {
//           PointerDeviceKind.touch,
//           PointerDeviceKind.mouse,
//           PointerDeviceKind.trackpad,
//         },
//       ),
//       child: Scrollbar(
//         thumbVisibility: true,
//         interactive: true,
//         child: SingleChildScrollView(
//           scrollDirection: Axis.horizontal,
//           child: SingleChildScrollView(
//             scrollDirection: Axis.vertical,  child: Column(
//       children: [
//         // 🌈 Gradient Header Row
//         Container(
//           decoration: BoxDecoration(
//             gradient: const LinearGradient(
//               colors: [Color(0xFF34D0C6), Color(0xFF22A4E0), Color(0xFF1565C0)],
//               begin: Alignment.centerLeft,
//               end: Alignment.centerRight,
//             ),
//             borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
//           ),
//           padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
//           child: Row(
//             children: const [
//               Expanded(child: Text("Name", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
//               Expanded(child: Text("Email", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
//               Expanded(child: Text("Phone", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
//               Expanded(child: Text("Designation", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
//               Expanded(child: Text("Join Date", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
//               Expanded(child: Text("Status", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
//               Expanded(child: Text("Actions", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
//             ],
//           ),
//         ),
//                               DataTable(
//                                 border: TableBorder.all(color: Colors.grey.shade300),
//                                headingRowColor: WidgetStateProperty.all(
//   const Color.fromARGB(255, 7, 106, 177), // 🌤️ light blue shade
// ),

//                                 headingTextStyle: const TextStyle(
//                                     color: Colors.black87, fontWeight: FontWeight.bold),
//                                 columns: const [
//                                 //  DataColumn(label: Text("Emp ID")),
//                                   DataColumn(label: Text("Name")),
//                                   DataColumn(label: Text("Email")),
//                                   DataColumn(label: Text("Phone")),
//                                   DataColumn(label: Text("Designation")),
//                                   DataColumn(label: Text("Join Date")),
//                                   DataColumn(label: Text("Status")),
//                                   DataColumn(label: Text("Actions")),
//                                 ],
//                                 rows: _filteredEmployees.map((doc) {
//                                   final data = doc.data() as Map<String, dynamic>;
//                                   return DataRow(cells: [
//                                    // DataCell(Text(data['emp_id'] ?? '')),
//                                     DataCell(Text(data['emp_name'] ?? '')),
//                                     DataCell(Text(data['emp_email'] ?? '')),
//                                     DataCell(Text(data['emp_phone'] ?? '')),
//                                     DataCell(Text(data['emp_designation'] ?? '')),
//                                     DataCell(Text(
//   data['emp_join_date'] != null
//       ? (data['emp_join_date'] is Timestamp
//           ? DateFormat('dd-MM-yyyy').format((data['emp_join_date'] as Timestamp).toDate())
//           : DateFormat('dd-MM-yyyy').format(DateTime.parse(data['emp_join_date'].toString())))
//       : '',
// )),

//                                     DataCell(Text(data['emp_status'] ?? '')),
//                                     DataCell(Row(
//                                       children: [
//                                         IconButton(
//                                           icon: const Icon(Icons.edit, color: Colors.blue),
//                                           onPressed: () {
//                                             // Navigate to edit form (you can pass doc.id or data)
//                                             Navigator.push(
//                                               context,
//                                               MaterialPageRoute(
//                                                 builder: (context) => EmployeeRegistration(
//                                                   currentUserId: widget.currentUserId,
//                                                   currentUserRole: widget.currentUserRole,
//                                                 ),
//                                               ),
//                                             );
//                                           },
//                                         ),
//                                         IconButton(
//                                           icon: const Icon(Icons.delete, color: Colors.red),
//                                           onPressed: () async {
//                                             final ok = await showDialog<bool>(
//                                               context: context,
//                                               builder: (_) => AlertDialog(
//                                                 title: const Text('Confirm delete'),
//                                                 content: const Text('Delete this employee?'),
//                                                 actions: [
//                                                   TextButton(
//                                                     onPressed: () => Navigator.pop(context, false),
//                                                     child: const Text('No'),
//                                                   ),
//                                                   TextButton(
//                                                     onPressed: () => Navigator.pop(context, true),
//                                                     child: const Text('Yes'),
//                                                   ),
//                                                 ],
//                                               ),
//                                             );
//                                             if (ok == true) deleteEmployee(doc.id);
//                                           },
//                                         ),
//                                       ],
//                                     )),
//                                   ]);
//                                 }).toList(),
//              ), ]
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                         ),
//                         ),
//                     ],                  
//                   ),
//                 ),

//                 // ➕ Floating button positioned bottom-right
//                 Positioned(
//                   right: isMobile ? 16 : 32,
//                   bottom: isMobile ? 16 : 32,
//                   child: GestureDetector(
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => EmployeeRegistration(
//                             currentUserId: widget.currentUserId,
//                             currentUserRole: widget.currentUserRole,
//                           ),
//                         ),
//                       );
//                     },
//                     child: Container(
//                       width: 56,
//                       height: 56,
//                       decoration: BoxDecoration(
//                         gradient: _gradient,
//                         shape: BoxShape.circle,
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.18),
//                             blurRadius: 8,
//                             offset: const Offset(0, 4),
//                           ),
//                         ],
//                       ),
//                       child: const Icon(Icons.add, color: Colors.white),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//     );
//   }
// }


// import 'dart:ui';
// import 'package:intl/intl.dart';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:task_management_application/utils/common/appbar_drawer.dart';

// class EmployeeListScreen extends StatefulWidget {
//   final String currentUserId;
//   final String currentUserRole;

//   const EmployeeListScreen({
//     super.key,
//     required this.currentUserId,
//     required this.currentUserRole,
//   });

//   @override
//   State<EmployeeListScreen> createState() => _EmployeeListScreenState();
// }

// class _EmployeeListScreenState extends State<EmployeeListScreen> {
//   final TextEditingController _filterController = TextEditingController();
//   final ScrollController _verticalScroll = ScrollController();
//   final ScrollController _horizontalScroll = ScrollController();

//   List<DocumentSnapshot> _employees = [];
//   List<DocumentSnapshot> _filteredEmployees = [];
//   bool _isLoading = true;
//   DocumentSnapshot? _selectedEmployee;

//   final LinearGradient _gradient = const LinearGradient(
//     colors: [Color(0xFF34D0C6), Color(0xFF22A4E0), Color(0xFF1565C0)],
//     begin: Alignment.centerLeft,
//     end: Alignment.centerRight,
//   );

//   @override
//   void initState() {
//     super.initState();
//     fetchEmployees();
//   }

//   Future<void> fetchEmployees() async {
//     setState(() => _isLoading = true);
//     final snapshot =
//         await FirebaseFirestore.instance.collection('employees').get();
//     setState(() {
//       _employees = snapshot.docs;
//       _filteredEmployees = _employees;
//       _isLoading = false;
//     });
//   }

//   void filterEmployees(String query) {
//     setState(() {
//       if (query.isEmpty) {
//         _filteredEmployees = _employees;
//       } else {
//         _filteredEmployees = _employees.where((doc) {
//           final data = doc.data() as Map<String, dynamic>;
//           final name = data['emp_name']?.toString().toLowerCase() ?? '';
//           final email = data['emp_email']?.toString().toLowerCase() ?? '';
//           final phone = data['emp_phone']?.toString().toLowerCase() ?? '';
//           final designation =
//               data['emp_designation']?.toString().toLowerCase() ?? '';
//           return name.contains(query.toLowerCase()) ||
//               email.contains(query.toLowerCase()) ||
//               phone.contains(query.toLowerCase()) ||
//               designation.contains(query.toLowerCase());
//         }).toList();
//       }
//     });
//   }

//   Future<void> deleteEmployee(String empId) async {
//     await FirebaseFirestore.instance.collection('employees').doc(empId).delete();
//     fetchEmployees();
//   }

//   Future<void> updateStatus(String empId, String newStatus) async {
//     await FirebaseFirestore.instance
//         .collection('employees')
//         .doc(empId)
//         .update({'emp_status': newStatus});
//   }

//   @override
//   Widget build(BuildContext context) {
//     final bool isMobile = MediaQuery.of(context).size.width < 600;

//     return CommonScaffold(
//       title: "Employee List",
//       role: widget.currentUserRole,
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Stack(
//               children: [
//                 Container(
//                   decoration: const BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: [Color(0xFFEAF6FF), Colors.white],
//                       begin: Alignment.topCenter,
//                       end: Alignment.bottomCenter,
//                     ),
//                   ),
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     children: [
//                       // 🔍 Search & Refresh Row
//                       Row(
//                         children: [
//                           Expanded(
//                             child: TextField(
//                               controller: _filterController,
//                               onChanged: filterEmployees,
//                               decoration: InputDecoration(
//                                 prefixIcon: const Icon(Icons.search),
//                                 hintText:
//                                     "Search by name, email, phone or designation",
//                                 filled: true,
//                                 fillColor: Colors.white,
//                                 contentPadding: const EdgeInsets.symmetric(
//                                     vertical: 12, horizontal: 12),
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                   borderSide: BorderSide.none,
//                                 ),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 10),
//                           Container(
//                             decoration: BoxDecoration(
//                               gradient: _gradient,
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: IconButton(
//                               onPressed: fetchEmployees,
//                               icon: const Icon(Icons.refresh, color: Colors.white),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 20),

//                       // 📋 Table Section
//                       Expanded(
//                         child: Container(
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.circular(12),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.grey.withOpacity(0.12),
//                                 blurRadius: 8,
//                                 offset: const Offset(0, 4),
//                               ),
//                             ],
//                           ),
//                           child: Scrollbar(
//                             controller: _horizontalScroll,
//                             thumbVisibility: true,
//                             child: SingleChildScrollView(
//                               controller: _horizontalScroll,
//                               scrollDirection: Axis.horizontal,
//                               child: DataTable(
//                                 border:
//                                     TableBorder.all(color: Colors.grey.shade300),
//                                 headingRowColor:
//                                     WidgetStateProperty.all(const Color(0xFF076AB1)),
//                                 headingTextStyle: const TextStyle(
//                                     color: Colors.white,
//                                     fontWeight: FontWeight.bold),
//                                 columns: const [
//                                   DataColumn(label: Text("Name")),
//                                   DataColumn(label: Text("Email")),
//                                   DataColumn(label: Text("Phone")),
//                                   DataColumn(label: Text("Designation")),
//                                   DataColumn(label: Text("Join Date")),
//                                   DataColumn(label: Text("Status")),
//                                   DataColumn(label: Text("Actions")),
//                                 ],
//                                 rows: _filteredEmployees.map((doc) {
//                                   final data =
//                                       doc.data() as Map<String, dynamic>;
//                                   return DataRow(cells: [
//                                     DataCell(Text(data['emp_name'] ?? '')),
//                                     DataCell(Text(data['emp_email'] ?? '')),
//                                     DataCell(Text(data['emp_phone'] ?? '')),
//                                     DataCell(Text(data['emp_designation'] ?? '')),
//                                     DataCell(Text(
//                                       data['emp_join_date'] != null
//                                           ? (data['emp_join_date'] is Timestamp
//                                               ? DateFormat('dd-MM-yyyy').format(
//                                                   (data['emp_join_date']
//                                                           as Timestamp)
//                                                       .toDate())
//                                               : DateFormat('dd-MM-yyyy').format(
//                                                   DateTime.parse(
//                                                       data['emp_join_date']
//                                                           .toString())))
//                                           : '',
//                                     )),
//                                     DataCell(
//                                       DropdownButton<String>(
//                                         value: data['emp_status'] ?? 'Active',
//                                         items: const [
//                                           DropdownMenuItem(
//                                               value: 'Active',
//                                               child: Text('Active')),
//                                           DropdownMenuItem(
//                                               value: 'Inactive',
//                                               child: Text('Inactive')),
//                                         ],
//                                         onChanged: (value) {
//                                           if (value != null) {
//                                             updateStatus(doc.id, value);
//                                             fetchEmployees();
//                                           }
//                                         },
//                                       ),
//                                     ),
//                                     DataCell(Row(
//                                       children: [
//                                         IconButton(
//                                           icon: const Icon(Icons.edit,
//                                               color: Colors.blue),
//                                           onPressed: () {
//                                             setState(() {
//                                               _selectedEmployee = doc;
//                                             });
//                                           },
//                                         ),
//                                         IconButton(
//                                           icon: const Icon(Icons.delete,
//                                               color: Colors.red),
//                                           onPressed: () async {
//                                             final ok = await showDialog<bool>(
//                                               context: context,
//                                               builder: (_) => AlertDialog(
//                                                 title: const Text('Confirm delete'),
//                                                 content: const Text(
//                                                     'Delete this employee?'),
//                                                 actions: [
//                                                   TextButton(
//                                                     onPressed: () => Navigator.pop(
//                                                         context, false),
//                                                     child: const Text('No'),
//                                                   ),
//                                                   TextButton(
//                                                     onPressed: () => Navigator.pop(
//                                                         context, true),
//                                                     child: const Text('Yes'),
//                                                   ),
//                                                 ],
//                                               ),
//                                             );
//                                             if (ok == true) deleteEmployee(doc.id);
//                                           },
//                                         ),
//                                       ],
//                                     )),
//                                   ]);
//                                 }).toList(),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),

//                       const SizedBox(height: 20),

//                       // ✏️ Edit Form Container
//                       if (_selectedEmployee != null)
//                         _buildEditContainer(_selectedEmployee!)
//                     ],
//                   ),
//                 ),

//                 // ➕ Floating Gradient Button
//                 Positioned(
//                   right: isMobile ? 16 : 32,
//                   bottom: isMobile ? 16 : 32,
//                   child: GestureDetector(
//                     onTap: () {
//                       setState(() {
//                         _selectedEmployee = null;
//                       });
//                     },
//                     child: Container(
//                       width: 56,
//                       height: 56,
//                       decoration: BoxDecoration(
//                         gradient: _gradient,
//                         shape: BoxShape.circle,
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.18),
//                             blurRadius: 8,
//                             offset: const Offset(0, 4),
//                           ),
//                         ],
//                       ),
//                       child: const Icon(Icons.add, color: Colors.white),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//     );
//   }
//  Widget _buildEditContainer(DocumentSnapshot doc) {
//   final data = doc.data() as Map<String, dynamic>;
//   final nameController = TextEditingController(text: data['emp_name']);
//   final emailController = TextEditingController(text: data['emp_email']);
//   final phoneController = TextEditingController(text: data['emp_phone']);
//   final designationController =
//       TextEditingController(text: data['emp_designation']);
//   final dateController = TextEditingController(
//     text: (data['emp_join_date'] is Timestamp)
//         ? DateFormat('dd-MM-yyyy')
//             .format((data['emp_join_date'] as Timestamp).toDate())
//         : (data['emp_join_date'] ?? '').toString(),
//   );
//   String selectedStatus = data['emp_status'] ?? 'Active';

//   return SingleChildScrollView( // ✅ added here (wraps entire widget)
//     child: Center(
//       child: Container(
//         width: 420,
//         margin: const EdgeInsets.only(top: 20, bottom: 20),
//         padding: const EdgeInsets.all(20),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.grey.withOpacity(0.25),
//               blurRadius: 8,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               "Edit Employee Details",
//               style: TextStyle(
//                 color: Colors.blue,
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 16),
//             _buildTextField("Name", nameController),
//             _buildTextField("Email", emailController),
//             _buildTextField("Phone", phoneController),
//             _buildTextField("Designation", designationController),
//             _buildTextField("Join Date", dateController, readOnly: true),

//             // ✅ Status Dropdown
//             Container(
//               margin: const EdgeInsets.only(bottom: 12),
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade100,
//                 border: Border.all(color: Colors.grey.shade300),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: DropdownButtonHideUnderline(
//                 child: DropdownButton<String>(
//                   value: selectedStatus,
//                   items: const [
//                     DropdownMenuItem(value: 'Active', child: Text('Active')),
//                     DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
//                   ],
//                   onChanged: (value) {
//                     if (value != null) {
//                       setState(() {
//                         selectedStatus = value;
//                       });
//                     }
//                   },
//                   isExpanded: true,
//                 ),
//               ),
//             ),

//             const SizedBox(height: 12),
//             Align(
//               alignment: Alignment.centerRight,
//               child: ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blue,
//                   foregroundColor: Colors.white,
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12)),
//                 ),
//                 onPressed: () async {
//                   await FirebaseFirestore.instance
//                       .collection('employees')
//                       .doc(doc.id)
//                       .update({
//                     'emp_name': nameController.text,
//                     'emp_email': emailController.text,
//                     'emp_phone': phoneController.text,
//                     'emp_designation': designationController.text,
//                     'emp_status': selectedStatus,
//                   });
//                   fetchEmployees();
//                   setState(() {
//                     _selectedEmployee = null;
//                   });
//                 },
//                 child: const Text("Update"),
//               ),
//             ),
//           ],
//         ),
//       ),
//     ),
//   );
// }



// Widget _buildTextField(String label, TextEditingController controller,
//     {bool readOnly = false}) {
//   return Container(
//     margin: const EdgeInsets.only(bottom: 12),
//     decoration: BoxDecoration(
//       color: Colors.grey.shade100,
//       borderRadius: BorderRadius.circular(12),
//       border: Border.all(color: Colors.grey.shade300),
//     ),
//     child: TextField(
//       controller: controller,
//       readOnly: readOnly,
//       decoration: InputDecoration(
//         labelText: label,
//         labelStyle: const TextStyle(color: Colors.grey),
//         contentPadding:
//             const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//         border: InputBorder.none,
//       ),
//     ),
//   );
// }
// }


import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_management_application/modules/Employee/presentation/views/employee_register.dart';
import 'package:task_management_application/utils/common/appbar_drawer.dart';

class EmployeeListScreen extends StatefulWidget {
  final String currentUserId;
  final String currentUserRole;

  const EmployeeListScreen({
    super.key,
    required this.currentUserId,
    required this.currentUserRole,
  });

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  final TextEditingController _filterController = TextEditingController();
  final ScrollController _horizontalScroll = ScrollController();

  List<DocumentSnapshot> _employees = [];
  List<DocumentSnapshot> _filteredEmployees = [];

  // departments fetched from Firestore: list of { 'dept_id':..., 'dept_name':... }
  List<Map<String, String>> _departments = [];
  bool _isLoadingDepartments = true;

  bool _isLoading = true;
  String? _editingEmployeeId;

  // controllers per employee for all text fields
  final Map<String, TextEditingController> _nameCtrls = {};
  final Map<String, TextEditingController> _emailCtrls = {};
  final Map<String, TextEditingController> _phoneCtrls = {};
  final Map<String, TextEditingController> _desigCtrls = {};
  final Map<String, TextEditingController> _permanentAddrCtrls = {};
  final Map<String, TextEditingController> _currentAddrCtrls = {};
  final Map<String, TextEditingController> _zipcodeCtrls = {};
  final Map<String, TextEditingController> _passwordCtrls = {};
  final Map<String, TextEditingController> _altPhoneCtrls = {};
final Map<String, TextEditingController> _aadharCtrls = {};
final Map<String, TextEditingController> _panCtrls = {};


  // dropdown/date state per employee
  final Map<String, String> _deptNameValues = {}; // emp_department (name)
  final Map<String, String> _genderValues = {};
  final Map<String, String> _cityValues = {};
  final Map<String, String> _stateValues = {};
  final Map<String, String> _countryValues = {};
  final Map<String, String> _statusValues = {};
  final Map<String, DateTime> _joinDateValues = {};
  final Map<String, DateTime> _dobValues = {};

  // static fallback lists for gender/country/state/city/status (you can alter)
  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _countries = ['India', 'USA', 'UK', 'Canada', 'Australia'];
  final List<String> _states = [
    'Maharashtra',
    'Delhi',
    'Karnataka',
    'Tamil Nadu',
    'West Bengal',
    'Telangana',
    'Gujarat'
  ];
  final List<String> _cities = [
    'Pune',
    'Mumbai',
    'Nagpur',
    'Nashik',
    'Bengaluru',
    'Chennai',
    'Ahmedabad',
    'Delhi'
  ];
  final List<String> _statuses = ['Active', 'Inactive', 'On Leave'];

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
    _loadDepartmentsAndEmployees();
  }

  Future<void> _loadDepartmentsAndEmployees() async {
    await fetchDepartments();
    await fetchEmployees();
  }

  Future<void> fetchDepartments() async {
    setState(() {
      _isLoadingDepartments = true;
    });
    try {
      final snapshot = await FirebaseFirestore.instance.collection('departments').get();
      final list = snapshot.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        return {
          'dept_id': (data['dept_id'] ?? '').toString(),
          'dept_name': (data['dept_name'] ?? '').toString(),
        };
      }).toList();
      setState(() {
        _departments = list;
        _isLoadingDepartments = false;
      });
    } catch (e) {
      debugPrint('Error fetching departments: $e');
      setState(() {
        _departments = [];
        _isLoadingDepartments = false;
      });
    }
  }

  Future<void> fetchEmployees() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance.collection('employees').get();
      setState(() {
        _employees = snapshot.docs;
        _filteredEmployees = _employees;
        _isLoading = false;
      });

      // initialize controllers & states from fetched data
      for (var doc in _employees) {
        final id = doc.id;
        final data = doc.data() as Map<String, dynamic>;

        _nameCtrls.putIfAbsent(id, () => TextEditingController(text: (data['emp_name'] ?? '').toString()));
        _emailCtrls.putIfAbsent(id, () => TextEditingController(text: (data['emp_email'] ?? '').toString()));
        _phoneCtrls.putIfAbsent(id, () => TextEditingController(text: (data['emp_phone'] ?? '').toString()));
        _desigCtrls.putIfAbsent(id, () => TextEditingController(text: (data['emp_designation'] ?? '').toString()));
        _permanentAddrCtrls.putIfAbsent(id, () => TextEditingController(text: (data['emp_permanent_address'] ?? '').toString()));
        _currentAddrCtrls.putIfAbsent(id, () => TextEditingController(text: (data['emp_current_address'] ?? '').toString()));
        _zipcodeCtrls.putIfAbsent(id, () => TextEditingController(text: (data['emp_zipcode'] ?? '').toString()));
        _passwordCtrls.putIfAbsent(id, () => TextEditingController(text: (data['emp_password'] ?? '').toString()));
_altPhoneCtrls.putIfAbsent(id, () => TextEditingController(text: (data['emp_alt_phone'] ?? '').toString()));
_aadharCtrls.putIfAbsent(id, () => TextEditingController(text: (data['emp_aadhar_no'] ?? '').toString()));
_panCtrls.putIfAbsent(id, () => TextEditingController(text: (data['emp_pan_no'] ?? '').toString()));

        _deptNameValues.putIfAbsent(id, () => (data['emp_department'] ?? '').toString());
        _genderValues.putIfAbsent(id, () => (data['emp_gender'] ?? _genders.first).toString());
        _cityValues.putIfAbsent(id, () => (data['emp_city'] ?? _cities.first).toString());
        _stateValues.putIfAbsent(id, () => (data['emp_state'] ?? _states.first).toString());
        _countryValues.putIfAbsent(id, () => (data['emp_country'] ?? _countries.first).toString());
        _statusValues.putIfAbsent(id, () => (data['emp_status'] ?? _statuses.first).toString());

        if (data['emp_join_date'] is Timestamp) {
          _joinDateValues.putIfAbsent(id, () => (data['emp_join_date'] as Timestamp).toDate());
        } else {
          _joinDateValues.putIfAbsent(id, () {
            final val = data['emp_join_date'];
            if (val == null) return DateTime.now();
            try {
              return DateTime.parse(val.toString());
            } catch (_) {
              return DateTime.now();
            }
          });
        }

        if (data['emp_dob'] is Timestamp) {
          _dobValues.putIfAbsent(id, () => (data['emp_dob'] as Timestamp).toDate());
        } else {
          _dobValues.putIfAbsent(id, () {
            final val = data['emp_dob'];
            if (val == null) return DateTime(1990);
            try {
              return DateTime.parse(val.toString());
            } catch (_) {
              return DateTime(1990);
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching employees: $e');
      setState(() => _isLoading = false);
    }
  }

  void filterEmployees(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredEmployees = _employees;
      } else {
        _filteredEmployees = _employees.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final fields = [
            data['emp_name']?.toString().toLowerCase() ?? '',
            data['emp_email']?.toString().toLowerCase() ?? '',
            data['emp_phone']?.toString().toLowerCase() ?? '',
            data['emp_designation']?.toString().toLowerCase() ?? '',
            data['emp_department']?.toString().toLowerCase() ?? '',
          ];
          return fields.any((f) => f.contains(query.toLowerCase()));
        }).toList();
      }
    });
  }

  Future<void> _saveRowEdits(String docId) async {
    // build update payload from controllers/states
    final updated = <String, dynamic>{
      'emp_name': _nameCtrls[docId]?.text ?? '',
      'emp_email': _emailCtrls[docId]?.text ?? '',
      'emp_phone': _phoneCtrls[docId]?.text ?? '',
      'emp_designation': _desigCtrls[docId]?.text ?? '',
      'emp_permanent_address': _permanentAddrCtrls[docId]?.text ?? '',
      'emp_current_address': _currentAddrCtrls[docId]?.text ?? '',
      'emp_zipcode': _zipcodeCtrls[docId]?.text ?? '',
      'emp_password': _passwordCtrls[docId]?.text ?? '',
      'emp_department': _deptNameValues[docId] ?? '',
      'emp_gender': _genderValues[docId] ?? '',
      'emp_city': _cityValues[docId] ?? '',
      'emp_state': _stateValues[docId] ?? '',
      'emp_country': _countryValues[docId] ?? '',
      'emp_status': _statusValues[docId] ?? '',
      'emp_join_date': _joinDateValues[docId],
      'emp_dob': _dobValues[docId],
      'emp_alt_phone': _altPhoneCtrls[docId]?.text ?? '',
'emp_aadhar_no': _aadharCtrls[docId]?.text ?? '',
'emp_pan_no': _panCtrls[docId]?.text ?? '',

    };

    try {
      await FirebaseFirestore.instance.collection('employees').doc(docId).update(updated);
      // refresh local list
      await fetchEmployees();
      setState(() => _editingEmployeeId = null);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Employee updated')));
    } catch (e) {
      debugPrint('Error saving employee updates: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
    }
  }

  Future<void> _cancelRowEdit(String docId) async {
    // reset controllers/state to values from Firestore by reloading employees (cheap approach)
    await fetchEmployees();
    setState(() => _editingEmployeeId = null);
  }

  Future<void> _deleteEmployee(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this employee?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await FirebaseFirestore.instance.collection('employees').doc(id).delete();
        await fetchEmployees();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Employee deleted')));
      } catch (e) {
        debugPrint('Delete error: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  Widget _buildEmployeeTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Scrollbar(
        controller: _horizontalScroll,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _horizontalScroll,
          scrollDirection: Axis.horizontal,
          child: DataTable(
            border: TableBorder.all(color: Colors.grey.shade300),
            headingRowColor: MaterialStateProperty.all(const Color(0xFF076AB1)),
            headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            columns: const [
              DataColumn(label: Text("Name")),
              DataColumn(label: Text("Email")),
              DataColumn(label: Text("Phone")),
              DataColumn(label: Text("Alt. Phone")),
              DataColumn(label: Text("Designation")),
              DataColumn(label: Text("Department")),
              DataColumn(label: Text("Gender")),
              DataColumn(label: Text("City")),
              DataColumn(label: Text("State")),
              DataColumn(label: Text("Country")),
              DataColumn(label: Text("Join Date")),
              DataColumn(label: Text("DOB")),
              DataColumn(label: Text("Status")),
              DataColumn(label: Text("Permanent Addr")),
              DataColumn(label: Text("Current Addr")),
              DataColumn(label: Text("Zipcode")),
              DataColumn(label: Text("Aadhar No")),
              DataColumn(label: Text("PAN No")),

              DataColumn(label: Text("Actions")),
            ],
            rows: _filteredEmployees.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final docId = doc.id;
              final isEditing = _editingEmployeeId == docId;

              // ensure initialization
              _nameCtrls.putIfAbsent(docId, () => TextEditingController(text: (data['emp_name'] ?? '').toString()));
              _emailCtrls.putIfAbsent(docId, () => TextEditingController(text: (data['emp_email'] ?? '').toString()));
              _phoneCtrls.putIfAbsent(docId, () => TextEditingController(text: (data['emp_phone'] ?? '').toString()));
              _desigCtrls.putIfAbsent(docId, () => TextEditingController(text: (data['emp_designation'] ?? '').toString()));
              _permanentAddrCtrls.putIfAbsent(docId, () => TextEditingController(text: (data['emp_permanent_address'] ?? '').toString()));
              _currentAddrCtrls.putIfAbsent(docId, () => TextEditingController(text: (data['emp_current_address'] ?? '').toString()));
              _zipcodeCtrls.putIfAbsent(docId, () => TextEditingController(text: (data['emp_zipcode'] ?? '').toString()));
              _passwordCtrls.putIfAbsent(docId, () => TextEditingController(text: (data['emp_password'] ?? '').toString()));

              _deptNameValues.putIfAbsent(docId, () => (data['emp_department'] ?? '').toString());
              _genderValues.putIfAbsent(docId, () => (data['emp_gender'] ?? _genders.first).toString());
              _cityValues.putIfAbsent(docId, () => (data['emp_city'] ?? _cities.first).toString());
              _stateValues.putIfAbsent(docId, () => (data['emp_state'] ?? _states.first).toString());
              _countryValues.putIfAbsent(docId, () => (data['emp_country'] ?? _countries.first).toString());
              _statusValues.putIfAbsent(docId, () => (data['emp_status'] ?? _statuses.first).toString());

              if (data['emp_join_date'] is Timestamp) {
                _joinDateValues.putIfAbsent(docId, () => (data['emp_join_date'] as Timestamp).toDate());
              } else {
                _joinDateValues.putIfAbsent(docId, () {
                  final v = data['emp_join_date'];
                  if (v == null) return DateTime.now();
                  try {
                    return DateTime.parse(v.toString());
                  } catch (_) {
                    return DateTime.now();
                  }
                });
              }

              if (data['emp_dob'] is Timestamp) {
                _dobValues.putIfAbsent(docId, () => (data['emp_dob'] as Timestamp).toDate());
              } else {
                _dobValues.putIfAbsent(docId, () {
                  final v = data['emp_dob'];
                  if (v == null) return DateTime(1990);
                  try {
                    return DateTime.parse(v.toString());
                  } catch (_) {
                    return DateTime(1990);
                  }
                });
              }

              final formattedJoin = DateFormat('dd-MM-yyyy').format(_joinDateValues[docId]!);
              final formattedDob = DateFormat('dd-MM-yyyy').format(_dobValues[docId]!);

              return DataRow(cells: [
                // Name
                DataCell(isEditing
                    ? SizedBox(width: 160, child: TextField(controller: _nameCtrls[docId]))
                    : Text(data['emp_name'] ?? '')),

                // Email
                DataCell(isEditing
                    ? SizedBox(width: 200, child: TextField(controller: _emailCtrls[docId]))
                    : Text(data['emp_email'] ?? '')),

                // Phone
                DataCell(isEditing
                    ? SizedBox(width: 120, child: TextField(controller: _phoneCtrls[docId]))
                    : Text(data['emp_phone'] ?? '')),
// Alt Phone
DataCell(isEditing
    ? SizedBox(width: 120, child: TextField(controller: _altPhoneCtrls[docId]))
    : Text(data['emp_alt_phone'] ?? '')),

                // Designation
                DataCell(isEditing ? TextField(controller: _desigCtrls[docId]) : Text(data['emp_designation'] ?? '')),

                // Department (dropdown showing dept_name fetched from Firestore)
                DataCell(isEditing
                    ? (_isLoadingDepartments
                        ? const SizedBox(width: 120, child: Center(child: CircularProgressIndicator()))
                        : DropdownButton<String>(
                            value: _deptNameValues[docId]!.isEmpty ? null : _deptNameValues[docId],
                            hint: const Text('Select Dept'),
                            items: _departments
                                .map((d) => DropdownMenuItem<String>(
                                      value: d['dept_name'],
                                      child: Text(d['dept_name'] ?? ''),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val == null) return;
                              setState(() {
                                _deptNameValues[docId] = val;
                              });
                            },
                          ))
                    : Text(data['emp_department'] ?? '')),

                // Gender
                DataCell(isEditing
                    ? DropdownButton<String>(
                        value: _genderValues[docId],
                        items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                        onChanged: (val) => setState(() => _genderValues[docId] = val ?? _genders.first),
                      )
                    : Text(data['emp_gender'] ?? '')),

                // City
                DataCell(isEditing ? TextField(controller: TextEditingController(text: _cityValues[docId])) : Text(data['emp_city'] ?? '')),

                // State
                DataCell(isEditing ? TextField(controller: TextEditingController(text: _stateValues[docId])) : Text(data['emp_state'] ?? '')),

                // Country
                DataCell(isEditing
                    ? DropdownButton<String>(
                        value: _countryValues[docId],
                        items: _countries.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) => setState(() => _countryValues[docId] = val ?? _countries.first),
                      )
                    : Text(data['emp_country'] ?? '')),

                // Join Date
                DataCell(isEditing
                    ? GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _joinDateValues[docId] ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) setState(() => _joinDateValues[docId] = picked);
                        },
                        child: Text(DateFormat('dd-MM-yyyy').format(_joinDateValues[docId]!)),
                      )
                    : Text(formattedJoin)),

                // DOB
                DataCell(isEditing
                    ? GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _dobValues[docId] ?? DateTime(1990),
                            firstDate: DateTime(1950),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) setState(() => _dobValues[docId] = picked);
                        },
                        child: Text(DateFormat('dd-MM-yyyy').format(_dobValues[docId]!)),
                      )
                    : Text(formattedDob)),

                // Status
                DataCell(isEditing
                    ? DropdownButton<String>(
                        value: _statusValues[docId],
                        items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) => setState(() => _statusValues[docId] = val ?? _statuses.first),
                      )
                    : Text(data['emp_status'] ?? '')),

                // Permanent Address
                DataCell(isEditing ? SizedBox(width: 180, child: TextField(controller: _permanentAddrCtrls[docId])) : Text(data['emp_permanent_address'] ?? '')),

                // Current Address
                DataCell(isEditing ? SizedBox(width: 180, child: TextField(controller: _currentAddrCtrls[docId])) : Text(data['emp_current_address'] ?? '')),

                // Zipcode
                DataCell(isEditing ? TextField(controller: _zipcodeCtrls[docId]) : Text(data['emp_zipcode'] ?? '')),



// Aadhar No
DataCell(isEditing
    ? SizedBox(width: 150, child: TextField(controller: _aadharCtrls[docId]))
    : Text(data['emp_aadhar_no'] ?? '')),

// PAN No
DataCell(isEditing
    ? SizedBox(width: 120, child: TextField(controller: _panCtrls[docId]))
    : Text(data['emp_pan_no'] ?? '')),

                // Actions
                DataCell(Row(
                  children: [
                    if (isEditing) ...[
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () async {
                          await _saveRowEdits(docId);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _cancelRowEdit(docId),
                      ),
                    ] else ...[
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          // when entering edit mode, ensure dept name fallback value is set from doc
                          _deptNameValues[docId] = (data['emp_department'] ?? '').toString();
                          setState(() => _editingEmployeeId = docId);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteEmployee(docId),
                      ),
                    ],
                  ],
                )),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }
@override
Widget build(BuildContext context) {
  return Scaffold(
    floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    floatingActionButton: Container(
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF34D0C6),
            Color(0xFF22A4E0),
            Color(0xFF1565C0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        elevation: 0,
        backgroundColor: Colors.transparent, // To show gradient
        tooltip: "Add New Employee",
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EmployeeRegistration(
                currentUserId: widget.currentUserId,
                currentUserRole: widget.currentUserRole,
              ),
            ),
          ).then((_) => fetchEmployees());
        },
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    ),

    body: Column(
      children: [
        // 🌈 Gradient AppBar
        Container(
          height: kToolbarHeight + 10,
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
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    "Employee List",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const CircleAvatar(
                    backgroundColor: Colors.white,
                    backgroundImage: AssetImage('assets/logo.png'),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 🧩 Body Section
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFEAF6FF), Colors.white],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // 🔍 Search + Refresh Row
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _filterController,
                              onChanged: filterEmployees,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.search),
                                hintText:
                                    "Search by name, email, phone, designation or department",
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF22A4E0),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: fetchEmployees,
                            icon: const Icon(Icons.refresh, color: Colors.white),
                            label: const Text(
                              "Refresh",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 🧾 Employee Table
                      Expanded(child: _buildEmployeeTable()),
                    ],
                  ),
                ),
        ),
      ],
    ),
  );
}
}