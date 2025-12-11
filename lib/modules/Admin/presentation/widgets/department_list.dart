import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_management_application/modules/Admin/presentation/widgets/add_department.dart';
import 'package:task_management_application/utils/common/pop_up_screen.dart';

class DepartmentListScreen extends StatefulWidget {
  final String currentUserId;
  final String currentUserRole;

  const DepartmentListScreen({
    super.key,
    required this.currentUserId,
    required this.currentUserRole,
  });

  @override
  State<DepartmentListScreen> createState() => _DepartmentListScreenState();
}

class _DepartmentListScreenState extends State<DepartmentListScreen> {
  String? _selectedDeptFilter;


 

  void _refresh() {
    setState(() => _selectedDeptFilter = null);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Departments",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Image.asset(
              'assets/logo.png', // ✅ Replace with your logo path
              height: 38,
              width: 38,
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

      // ✅ Floating Add Button
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.rectangle,
           borderRadius: BorderRadius.circular(8),
          gradient: const LinearGradient(
            colors: [Color(0xFF34D0C6), Color(0xFF22A4E0), Color(0xFF1565C0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddDepartmentScreen(
                // currentUserId: widget.currentUserId,
                // currentUserRole: widget.currentUserRole,
              ),
            ),
          );
        },
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔹 Filter & Refresh Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('departments')
                        .orderBy('dept_name')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      final deptNames = snapshot.data!.docs
                          .map((doc) => doc['dept_name'] as String)
                          .toList();

                      return Container(
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF34D0C6), Color(0xFF22A4E0)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(1.5),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedDeptFilter,
                              hint: const Text(
                                "Filter by Department",
                                style: TextStyle(fontSize: 14),
                              ),
                              isExpanded: true,
                              icon: const Icon(Icons.arrow_drop_down,
                                  color: Color(0xFF22A4E0)),
                              items: deptNames
                                  .map((dept) => DropdownMenuItem(
                                        value: dept,
                                        child: Text(dept),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedDeptFilter = value;
                                });
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                // 🔹 Refresh Button with Gradient Border
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF34D0C6), Color(0xFF22A4E0)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(1.5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh, color: Color(0xFF22A4E0)),
                      tooltip: "Refresh",
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 🔹 Department Grid
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('departments')
                    .orderBy('created_at', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF22A4E0)));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "No departments found.",
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    );
                  }

                  var departments = snapshot.data!.docs;

                  if (_selectedDeptFilter != null) {
                    departments = departments
                        .where((d) =>
                            d['dept_name']
                                .toString()
                                .toLowerCase()
                                .contains(_selectedDeptFilter!.toLowerCase()))
                        .toList();
                  }

                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isDesktop ? 3 : 1,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: isDesktop ? 3 : 2.8,
                    ),
                    itemCount: departments.length,
                    itemBuilder: (context, index) {
                      final dept = departments[index];
                      final deptName = dept['dept_name'] ?? 'Unknown';

                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF34D0C6), Color(0xFF22A4E0)],
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(1.5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            leading: const Icon(Icons.apartment,
                                color: Color(0xFF22A4E0)),
                            title: Text(
                              deptName,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // subtitle: Text(
                            //   "Created on: $createdAt",
                            //   style: const TextStyle(
                            //     color: Colors.black54,
                            //     fontSize: 13,
                            //   ),
                            // ),
                            trailing: PopupMenuButton<String>(
                              color: Colors.white,
                              onSelected: (value) async {
                                if (value == 'delete') {
                                  await FirebaseFirestore.instance
                                      .collection('departments')
                                      .doc(dept.id)
                                      .delete();
                                  showCustomAlert(
                                    context,
                                    isSuccess: true,
                                    title: "Deleted",
                                    description:
                                        "Department '$deptName' deleted successfully.",
                                  );
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: Colors.red),
                                      SizedBox(width: 6),
                                      Text("Delete"),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
}
