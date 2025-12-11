import 'package:flutter/material.dart';
import 'package:task_management_application/modules/Attendance/presentation/views/add_attendance.dart';
import 'package:task_management_application/modules/Attendance/presentation/views/leave_appliaction.dart';
import 'package:task_management_application/modules/Attendance/presentation/views/leave_list.dart';
import 'package:task_management_application/modules/Attendance/presentation/views/view_attendance.dart';
import 'package:task_management_application/modules/Attendance/presentation/views/view_intern_attendance.dart';
import 'package:task_management_application/utils/common/appbar_drawer.dart';
import 'package:task_management_application/utils/common/custom_button.dart';

class ManageAttendanceScreen extends StatelessWidget {
  final String currentUserId;
  final String currentUserRole;

  const ManageAttendanceScreen({
    super.key,
    required this.currentUserId,
    required this.currentUserRole,
  });

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      title: "Manage Attendance",
      role: currentUserRole,
      body: LayoutBuilder(
        builder: (context, constraints) {
          double maxWidth = constraints.maxWidth;

          bool isMobile = maxWidth < 600;
          bool isTablet = maxWidth >= 600 && maxWidth < 1024;

          double buttonWidth = isMobile
              ? double.infinity
              : (isTablet ? 280 : 300);

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: [
                  CustomButton(
                    label: "Attendance",
                    icon: Icons.access_time,
                    width: buttonWidth,
                    height: 60,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AttendanceScreen(
                            currentUserId: currentUserId,
                            currentUserRole: currentUserRole,
                          ),
                        ),
                      );
                    },
                  ),

                  CustomButton(
                    label: "Employee Attendance",
                    icon: Icons.visibility,
                    width: buttonWidth,
                    height: 60,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AttendanceDashboardAllScreen(
                            currentUserId: currentUserId,
                            currentUserRole: currentUserRole,
                          ),
                        ),
                      );
                    },
                  ),

                  CustomButton(
                    label: "Intern Attendance",
                    icon: Icons.visibility,
                    width: buttonWidth,
                    height: 60,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InternAttendanceDashboardScreen(
                            currentUserId: currentUserId,
                            currentUserRole: currentUserRole,
                          ),
                        ),
                      );
                    },
                  ),

                  CustomButton(
                    label: "Leave Applications",
                    icon: Icons.event_note,
                    width: buttonWidth,
                    height: 60,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LeaveApplicationsScreen(),
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


// ---------------- Report Tab ----------------
class ReportTabScreen extends StatelessWidget {
  final String currentUserId;
  final String currentUserRole;

  const ReportTabScreen({
    super.key,
    required this.currentUserId,
    required this.currentUserRole,
  });

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      title: "Attendance Report",
      role: currentUserRole,
      body: const Center(
        child: Text(
          "Report Section",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
