import 'package:flutter/material.dart';
import 'package:task_management_application/modules/Admin/presentation/widgets/add_department.dart';
import 'package:task_management_application/modules/Admin/presentation/widgets/department_list.dart';
import 'package:task_management_application/utils/common/appbar_drawer.dart';
import 'package:task_management_application/utils/common/custom_button.dart';

class ManageDepartmentScreen extends StatelessWidget {
  final String currentUserId;
  final String currentUserRole;

  const ManageDepartmentScreen({
    super.key,
    required this.currentUserId,
    required this.currentUserRole,
  });

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      title: "Department Dashboard",
      role: currentUserRole,
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 600;
          bool isTablet =
              constraints.maxWidth >= 600 && constraints.maxWidth < 1024;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Flex(
                direction: isMobile ? Axis.vertical : Axis.horizontal,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ---------------- Department List ----------------
                  CustomButton(
                    label: "Department List",
                    icon: Icons.list_alt,
                    width: isMobile
                        ? double.infinity
                        : (isTablet ? 200 : 250),
                    height: 60,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DepartmentListScreen(
                            currentUserId: currentUserId,
                            currentUserRole: currentUserRole,
                          ),
                        ),
                      );
                    },
                  ),

                  SizedBox(
                      height: isMobile ? 16 : 0,
                      width: isMobile ? 0 : 16),

                  // ---------------- Add Department ----------------
                  CustomButton(
                    label: "Add Department",
                    icon: Icons.add_business,
                    width: isMobile
                        ? double.infinity
                        : (isTablet ? 200 : 250),
                    height: 60,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddDepartmentScreen( ),
                        ),
                      );
                    },
                  ),

                  SizedBox(
                      height: isMobile ? 16 : 0,
                      width: isMobile ? 0 : 16),

                  // ---------------- Reports ----------------
                  // CustomButton(
                  //   label: "Reports",
                  //   icon: Icons.analytics,
                  //   width: isMobile
                  //       ? double.infinity
                  //       : (isTablet ? 200 : 250),
                  //   height: 60,
                  //   onPressed: () {
                  //     // TODO: Navigate to DepartmentReportsScreen
                  //   },
                  // ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
