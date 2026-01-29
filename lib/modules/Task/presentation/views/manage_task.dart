import 'package:flutter/material.dart';
import 'package:task_management_application/modules/Report/presentation/views/employee_progress.dart';
import 'package:task_management_application/modules/Report/presentation/views/task_report.dart';
import 'package:task_management_application/modules/Task/presentation/views/employee_task_list.dart';
import 'package:task_management_application/utils/common/appbar_drawer.dart';
import 'package:task_management_application/utils/common/custom_button.dart';

class ManageTaskScreen extends StatelessWidget {
  final String currentUserId;
  final String currentUserRole;

  const ManageTaskScreen({
    super.key,
    required this.currentUserId,
    required this.currentUserRole,
  });

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      title: "Manage Tasks",
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
                  CustomButton(
                    label: "Edit Task List",
                    icon: Icons.badge,
                    width: isMobile ? double.infinity : (isTablet ? 220 : 250),
                    height: 70,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => EmployeeTaskListScreen(
                                currentUserId: currentUserId,
                                currentUserRole: currentUserRole,
                              ),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: isMobile ? 16 : 0, width: isMobile ? 0 : 16),

                  CustomButton(
                    label: "Task Report",
                    icon: Icons.school,
                    width: isMobile ? double.infinity : (isTablet ? 220 : 250),
                    height: 70,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => EmployeeInternScreen(
                                //  currentUserId: currentUserId,
                                //   currentUserRole: currentUserRole,
                              ),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: isMobile ? 16 : 0, width: isMobile ? 0 : 16),

                  CustomButton(
                    label: "Progress Report",
                    icon: Icons.school,
                    width: isMobile ? double.infinity : (isTablet ? 220 : 250),
                    height: 70,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EmployeePerformanceDashboard(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
