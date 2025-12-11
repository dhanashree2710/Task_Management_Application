import 'package:flutter/material.dart';
import 'package:task_management_application/modules/Interns/presentation/views/interns_list.dart';
import 'package:task_management_application/modules/Interns/presentation/views/interns_register.dart';
import 'package:task_management_application/utils/common/appbar_drawer.dart';
import 'package:task_management_application/utils/common/custom_button.dart';

class ManageInternScreen extends StatelessWidget {
  final String currentUserId;
  final String currentUserRole;

  const ManageInternScreen({
    super.key,
    required this.currentUserId,
    required this.currentUserRole,
  });

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      title: "Intern Dashboard",
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
                  // ---------------- Intern List ----------------
                  CustomButton(
                    label: "Intern List",
                    icon: Icons.list_alt,
                    width:
                        isMobile ? double.infinity : (isTablet ? 200 : 250),
                    height: 60,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InternListScreen(
                            currentUserId: currentUserId,
                            currentUserRole: currentUserRole,
                          ),
                        ),
                      );
                    },
                  ),

                  SizedBox(
                      height: isMobile ? 16 : 0, width: isMobile ? 0 : 16),

                  // ---------------- Register Intern ----------------
                  CustomButton(
                    label: "Register Intern",
                    icon: Icons.person_add,
                    width:
                        isMobile ? double.infinity : (isTablet ? 200 : 250),
                    height: 60,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InternRegistration(
                            currentUserId: currentUserId,
                            currentUserRole: currentUserRole,
                          ),
                        ),
                      );
                    },
                  ),

                  SizedBox(
                      height: isMobile ? 16 : 0, width: isMobile ? 0 : 16),

                  // // ---------------- Attendance ----------------
                  // CustomButton(
                  //   label: "Attendance",
                  //   icon: Icons.access_time,
                  //   width:
                  //       isMobile ? double.infinity : (isTablet ? 200 : 250),
                  //   height: 60,
                  //   onPressed: () {
                  //     // TODO: Navigate to InternAttendanceScreen
                  //   },
                  // ),

                  // SizedBox(
                  //     height: isMobile ? 16 : 0, width: isMobile ? 0 : 16),

                  // // ---------------- Tasks ----------------
                  // CustomButton(
                  //   label: "Intern Tasks",
                  //   icon: Icons.task_alt,
                  //   width:
                  //       isMobile ? double.infinity : (isTablet ? 200 : 250),
                  //   height: 60,
                  //   onPressed: () {
                  //     // TODO: Navigate to InternTaskScreen
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
                  //     // TODO: Navigate to InternReportScreen
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
