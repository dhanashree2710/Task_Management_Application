import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:task_management_application/modules/Admin/presentation/views/super_admin/admin_dashboard.dart';
import 'package:task_management_application/modules/Admin/presentation/widgets/mange_department_screen.dart';
import 'package:task_management_application/modules/Attendance/presentation/views/Employee_leave_feedback_screen.dart';
import 'package:task_management_application/modules/Attendance/presentation/views/add_attendance.dart';
import 'package:task_management_application/modules/Attendance/presentation/views/leave_appliaction.dart';
import 'package:task_management_application/modules/Attendance/presentation/views/particular_user_attendence.dart';
import 'package:task_management_application/modules/Attendance/presentation/widgets/manage_attendance.dart';
import 'package:task_management_application/modules/Employee/presentation/views/employee_dashboard.dart';
import 'package:task_management_application/modules/Employee/presentation/widgets/mange_employee_screen.dart';
import 'package:task_management_application/modules/Interns/presentation/views/intern_dashboard.dart';
import 'package:task_management_application/modules/Interns/presentation/widgets/mange_interns_screen.dart';
import 'package:task_management_application/modules/Login/presentation/views/user_role_List.dart';
import 'package:task_management_application/modules/Login/presentation/views/user_role_login.dart';
import 'package:task_management_application/modules/Report/presentation/views/particluar_user_report.dart';
import 'package:task_management_application/modules/Task/presentation/views/intern_task_list.dart';
import 'package:task_management_application/modules/Task/presentation/views/manage_task.dart';
import 'package:task_management_application/modules/Task/presentation/views/task_allocation.dart';
import 'package:task_management_application/utils/common/user_session.dart';
import 'package:universal_platform/universal_platform.dart';
import '../components/kdrt_colors.dart';

class CommonScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final String role;
  final String? empId;

  const CommonScaffold({
    super.key,
    this.empId,
    required this.title,
    required this.body,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF34D0C6), Color(0xFF22A4E0), Color(0xFF1565C0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: AssetImage('assets/logo.png'),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: body,
    );
  }

  /// === Drawer based on role ===
  Widget _buildDrawer(BuildContext context) {
    List<Widget> menuItems = [
      DrawerHeader(
        decoration: const BoxDecoration(color: Colors.white),
        child: Image.asset(
          role == "admin" || role == "super admin"
              ? 'assets/admin_drawer.jpg'
              : 'assets/employee_drawer.jpg',
          fit: BoxFit.cover,
        ),
      ),

      ListTile(
        leading: const Icon(Icons.home, color: KDRTColors.darkBlue),
        title: const Text("Dashboard"),
        onTap: () {
          Navigator.pop(context); // Close the drawer first

          // Determine which dashboard to open based on role
          Widget dashboardPage;

          if (role == "admin" || role == "super admin") {
            dashboardPage = AdminDashboard();
          } else if (role == "employee") {
            dashboardPage = EmployeeDashboardScreen(
              currentUserId: UserSession().userId ?? '',
              currentUserRole: role,
            );
          } else {
            // Default fallback
            dashboardPage = InternDashboardScreen(
              currentUserId: UserSession().userId ?? '',
              currentUserRole: role,
            );
          }

          // Clear all previous screens and go to Dashboard
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => dashboardPage),
            (route) => false, // Remove all routes to make dashboard the root
          );
        },
      ),
    ];

    // === Admin Role ===
    if (role == "admin") {
      menuItems.addAll([
        // _drawerItem(
        //   context,
        //   icon: Icons.person_add,
        //   label: "Register User",
        //   page: UserRoleRegistration(currentUserRole: role),
        // ),
        _drawerItem(
          context,
          icon: Icons.assignment,
          label: "Manage Attendance",
          page: ManageAttendanceScreen(
            currentUserId: UserSession().userId ?? '',
            currentUserRole: role,
          ),
        ),
        _drawerItem(
          context,
          icon: Icons.people_alt,
          label: "Manage Employee",
          page: ManageEmployeeScreen(
            currentUserId: UserSession().userId ?? '',
            currentUserRole: role,
          ),
        ),
        _drawerItem(
          context,
          icon: Icons.school,
          label: "Manage Interns",
          page: ManageInternScreen(
            currentUserId: UserSession().userId ?? '',
            currentUserRole: role,
          ),
        ),
        _drawerItem(
          context,
          icon: Icons.manage_accounts,
          label: "Manage User Role",
          page: UserListScreen(
            currentUserId: UserSession().userId ?? '',
            currentUserRole: role,
          ),
        ),

        _drawerItem(
          context,
          icon: Icons.task_rounded,
          label: "Tasks Allocation",
          page: TaskAllocationScreen(
            currentUserId: UserSession().userId ?? '',
            currentUserRole: role,
          ),
        ),
        _drawerItem(
          context,
          icon: Icons.business_outlined,
          label: "Manage Department",
          page: ManageDepartmentScreen(
            currentUserId: UserSession().userId ?? '',
            currentUserRole: role,
          ),
        ),
        _drawerItem(
          context,
          icon: Icons.assignment_outlined,
          label: "Manage Task",
          page: ManageTaskScreen(
            currentUserId: UserSession().userId ?? '',
            currentUserRole: role,
          ),
        ),

        // _drawerItem(
        //   context,
        //   icon: Icons.person_add_alt,
        //   label: "Manage Visitors",
        //   page: const VisitorDashboardPage(),
        // ),
        // _drawerItem(
        //   context,
        //   icon: Icons.report_problem,
        //   label: "Manage Grievances",
        //   page: const ManageGrievanceScreen(),
        // ),
      ]);
    }
    // === Super Admin Role ===
    else if (role == "super admin") {
      menuItems.addAll([
        // _drawerItem(
        //   context,
        //   icon: Icons.person_add,
        //   label: "Register User",
        //   page:UserRoleRegistration(currentUserRole: role),
        // ),
        _drawerItem(
          context,
          icon: Icons.assignment,
          label: "Manage Attendance",
          page: ManageAttendanceScreen(
            currentUserId: UserSession().userId ?? '',
            currentUserRole: role,
          ),
        ),
        _drawerItem(
          context,
          icon: Icons.people,
          label: "Manage Employee",
          page: ManageEmployeeScreen(
            currentUserId: UserSession().userId ?? '',
            currentUserRole: role,
          ),
        ),
        _drawerItem(
          context,
          icon: Icons.people,
          label: "Manage Interns",
          page: ManageInternScreen(
            currentUserId: UserSession().userId ?? '',
            currentUserRole: role,
          ),
        ),
        _drawerItem(
          context,
          icon: Icons.task_rounded,
          label: "Tasks Allocation",
          page: TaskAllocationScreen(
            currentUserId: UserSession().userId ?? '',
            currentUserRole: role,
          ),
        ),
        _drawerItem(
          context,
          icon: Icons.business_outlined,
          label: "Manage Department",
          page: ManageDepartmentScreen(
            currentUserId: UserSession().userId ?? '',
            currentUserRole: role,
          ),
        ),
        _drawerItem(
          context,
          icon: Icons.assignment_outlined,
          label: "Manage Task",
          page: ManageTaskScreen(
            currentUserId: UserSession().userId ?? '',
            currentUserRole: role,
          ),
        ),

        // _drawerItem(
        //   context,
        //   icon: Icons.people_alt,
        //   label: "Manage Employees",
        //   page: const ManageEmployeeScreen(),
        // ),
        // _drawerItem(
        //   context,
        //   icon: Icons.report_problem_outlined,
        //   label: "Manage Grievances",
        //   page: const ManageGrievanceScreen(),
        // ),
      ]);
    }
    // === Employee Role ===
    else if (role == "employee") {
      menuItems.addAll([
        _drawerItem(
          context,
          icon: Icons.access_time,
          label: "Attendance",
          page: AttendanceScreen(
            currentUserId: UserSession().userId ?? '',
            currentUserRole: role,
          ),
        ),
        _drawerItem(
          context,
            icon: Icons.visibility,
          label: "View Attendance",
          page: AttendanceDashboardForLoginUser(
            currentUserId: UserSession().userId ?? '',
            currentUserRole: role,
          ),
        ),
        _drawerItem(
          context,
          icon: Icons.event_busy,

          label: "Leave Appliaction",
          page: LeaveApplicationScreen(
            currentUserId: UserSession().userId ?? '',
            currentUserRole: role,
          ),
        ),
        _drawerItem(
          context,
          icon: Icons.assignment_turned_in,
          label: "Leave Status",
          page: EmployeeLeaveHistoryScreen(
            currentUserId: UserSession().userId ?? '',
          ),
        ),
        _drawerItem(
          context,
          icon: Icons.task_rounded,
          label: "Tasks Allocation",
          page: TaskAllocationScreen(
            currentUserId: UserSession().userId ?? '',
            currentUserRole: role,
          ),
        ),
        _drawerItem(
          context,
          icon: Icons.assignment,
          label: "Task List",
          page: ParticularEmployeeTaskListScreen(
            currentUserId: UserSession().userId ?? '',
            currentUserRole: role,
          ),
        ),
        _drawerItem(
          context,
          icon: Icons.school,
          label: "Task Report",
          page: EmployeeTaskReportScreen(
          employeeId: UserSession().userId ?? '',       
          
          ),
        ),
        //   _drawerItem(
        //   context,
        //   icon: Icons.assignment,
        //   label: "Task List",
        //   onTap: () async {
        //     final user = FirebaseAuth.instance.currentUser;
        //     if (user == null) {
        //       ScaffoldMessenger.of(context).showSnackBar(
        //         const SnackBar(content: Text("User not logged in")),
        //       );
        //       return;
        //     }

        //     debugPrint("✅ Navigating to Employee Task List for UID: ${user.uid}");

        //     Navigator.pop(context); // Close drawer
        //     Navigator.push(
        //       context,
        //       MaterialPageRoute(
        //         builder: (context) => ParticluarEmployeeTaskListScreen(
        //           currentUserId: user.uid,
        //           currentUserRole: role,
        //         ),
        //       ),
        //     );
        //   },
        // ),

        //   _drawerItem(
        //   context,
        //   icon: Icons.assignment,
        //   label: "Manage Attendance",
        //   page: ManageAttendanceScreen(
        //     currentUserId: UserSession().userId ?? '',
        //     currentUserRole: role,
        //   ),
        // ),

        // _drawerItem(
        //   context,
        //   icon: Icons.report_problem,
        //   label: "Manage Grievances",
        //   page: const ManageGrievanceScreen(),
        // ),
      ]);
    }
    // === Intern Role ===
    else if (role == "intern") {
      menuItems.addAll([
        _drawerItem(
          context,
          icon: Icons.access_time,
          label: "Attendance",
          page: AttendanceScreen(
            currentUserId: UserSession().userId ?? '',
            currentUserRole: role,
          ),
        ),
         _drawerItem(
          context,
            icon: Icons.visibility,
          label: "View Attendance",
          page: AttendanceDashboardForLoginUser(
            currentUserId: UserSession().userId ?? '',
            currentUserRole: role,
          ),
        ),
        _drawerItem(
          context,
          icon: Icons.event_busy,

          label: "Leave Appliaction",
          page: LeaveApplicationScreen(
            currentUserId: UserSession().userId ?? '',
            currentUserRole: role,
          ),
        ),
        _drawerItem(
          context,
          icon: Icons.assignment_turned_in,
          label: "Leave Status",
          page: EmployeeLeaveHistoryScreen(
            currentUserId: UserSession().userId ?? '',
          ),
        ),
        _drawerItem(
          context,
          icon: Icons.assignment,
          label: "Task List",
          page: ParticularEmployeeTaskListScreen(
            currentUserId: UserSession().userId ?? '',
            currentUserRole: role,
          ),
        ),
        _drawerItem(
          context,
          icon: Icons.school,
          label: "Task Report",
          page: EmployeeTaskReportScreen(
          employeeId: UserSession().userId ?? '',
          
          ),
        ),
      ]);
    }

    // === Logout option for all roles ===
    menuItems.add(
      ListTile(
        leading: const Icon(Icons.logout, color: Colors.red),
        title: const Text("Logout", style: TextStyle(color: Colors.red)),
        onTap: () => _showLogoutConfirmation(context),
      ),
    );

    return Drawer(
      backgroundColor: Colors.white,
      child: SingleChildScrollView(child: Column(children: menuItems)),
    );
  }

  /// === Drawer item builder ===
  Widget _drawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    Widget? page,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: KDRTColors.darkBlue),
      title: Text(label),
      onTap:
          onTap ??
          () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => page!),
            );
          },
    );
  }

  /// === Logout confirmation dialog ===
  void _showLogoutConfirmation(BuildContext context) async {
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => Dialog(
            backgroundColor: KDRTColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Lottie.asset(
                    'assets/confirmation.json',
                    height: 120,
                    width: 120,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Are you sure you want to logout?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            await FirebaseAuth.instance.signOut();

                            // Navigate to role selection screen
                            Navigator.pop(context);
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UserLoginScreen(),
                              ),
                              (route) => false,
                            );

                            // Close app if required
                            if (UniversalPlatform.isDesktop) {
                              exit(0);
                            } else if (UniversalPlatform.isMobile) {
                              SystemNavigator.pop();
                            }
                          } catch (e) {
                            debugPrint('Logout error: $e');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: KDRTColors.darkBlue,
                        ),
                        child: const Text('Yes'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: KDRTColors.cyan,
                        ),
                        child: const Text('No'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
