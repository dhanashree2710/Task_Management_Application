import 'package:flutter/material.dart';
import 'package:task_management_application/modules/Employee/presentation/views/employee_list.dart';
import 'package:task_management_application/modules/Employee/presentation/views/employee_register.dart';
import 'package:task_management_application/utils/common/appbar_drawer.dart';
import 'package:task_management_application/utils/common/custom_button.dart';

class ManageEmployeeScreen extends StatelessWidget {
  final String currentUserId;
  final String currentUserRole;

  const ManageEmployeeScreen({
    super.key,
    required this.currentUserId,
    required this.currentUserRole,
  });

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      title: "Employee Dashboard",
      role: currentUserRole, // ✅ Now uses actual user role
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
                  // ---------------- Employee List ----------------
                  CustomButton(
                    label: "Employee List",
                    icon: Icons.list_alt,
                    width:
                        isMobile ? double.infinity : (isTablet ? 200 : 250),
                    height: 60,
                    onPressed: () {
                       Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EmployeeListScreen(
                            currentUserId: currentUserId,
                            currentUserRole: currentUserRole,
                          ),
                        ),
                      );
                    },
                  ),

                  SizedBox(
                      height: isMobile ? 16 : 0, width: isMobile ? 0 : 16),

                  // ---------------- Register Employee ----------------
                  CustomButton(
                    label: "Register Employee",
                    icon: Icons.person_add,
                    width:
                        isMobile ? double.infinity : (isTablet ? 200 : 250),
                    height: 60,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EmployeeRegistration(
                            currentUserId: currentUserId,
                            currentUserRole: currentUserRole,
                          ),
                        ),
                      );
                    },
                  ),

                  SizedBox(
                      height: isMobile ? 16 : 0, width: isMobile ? 0 : 16),

                  // ---------------- Attendance ----------------
                  // CustomButton(
                  //   label: "Attendance",
                  //   icon: Icons.access_time,
                  //   width:
                  //       isMobile ? double.infinity : (isTablet ? 200 : 250),
                  //   height: 60,
                  //   onPressed: () {
                  //     // TODO: Navigate to AttendanceScreen
                  //   },
                  // ),

                  // SizedBox(
                  //     height: isMobile ? 16 : 0, width: isMobile ? 0 : 16),

                  // // ---------------- Leave Application ----------------
                  // CustomButton(
                  //   label: "Leave Application",
                  //   icon: Icons.event_note,
                  //   width:
                  //       isMobile ? double.infinity : (isTablet ? 200 : 250),
                  //   height: 60,
                  //   onPressed: () {
                  //     // TODO: Navigate to LeaveApplicationScreen
                  //   },
                  // ),

                  // SizedBox(
                  //     height: isMobile ? 16 : 0, width: isMobile ? 0 : 16),

                  // // ---------------- Reports ----------------
                  // CustomButton(
                  //   label: "Reports",
                  //   icon: Icons.analytics,
                  //   width:
                  //       isMobile ? double.infinity : (isTablet ? 200 : 250),
                  //   height: 60,
                  //   onPressed: () {
                  //     // TODO: Navigate to EmployeeReportScreen
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
