// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:task_management_application/modules/Login/presentation/views/user_role_login.dart';


// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _animation;

//   @override
//   void initState() {
//     super.initState();

//     _controller = AnimationController(
//       duration: const Duration(seconds: 2),
//       vsync: this,
//     )..forward();

//     _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

//     // Navigate to Login Screen after 3 seconds
//     Timer(const Duration(seconds: 3), () {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const UserLoginScreen()),
//       );
//     });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   // Responsive Layout
//   double _getResponsiveSize(BuildContext context) {
//     double width = MediaQuery.of(context).size.width;
//     if (width < 600) return 150; // mobile
//     if (width < 1024) return 200; // tablet
//     return 250; // desktop
//   }

//   @override
//   Widget build(BuildContext context) {
//     double imageSize = _getResponsiveSize(context);

//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Center(
//         child: FadeTransition(
//           opacity: _animation,
//           child: ScaleTransition(
//             scale: _animation,
//             child: Image.asset(
//               'assets/logo.png', // 👈 Replace with your image path
//               width: imageSize,
//               height: imageSize,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:task_management_application/modules/Admin/presentation/views/super_admin/admin_dashboard.dart';
import 'package:task_management_application/modules/Employee/presentation/views/employee_dashboard.dart';
import 'package:task_management_application/modules/Interns/presentation/views/intern_dashboard.dart';
import 'package:task_management_application/modules/Login/data/models/user_session.dart';
import 'package:task_management_application/modules/Login/presentation/views/user_role_login.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>  with SingleTickerProviderStateMixin {

    late AnimationController _controller;
   late Animation<double> _animation;

 @override
void initState() {
  super.initState();
  _checkSession();

  _controller = AnimationController(
    duration: const Duration(seconds: 2),
    vsync: this,
  )..forward();

  _animation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );
}


 Future<void> _checkSession() async {
  await Future.delayed(const Duration(seconds: 2));

  final session = UserSession();
  final loggedIn = await session.isLoggedIn();
  final role = await session.role;
  final uid = await session.userId;

  debugPrint("🔍 SPLASH CHECK → loggedIn=$loggedIn role=$role uid=$uid");

  if (!loggedIn || role.isEmpty) {
    _go(const UserLoginScreen());
    return;
  }

  switch (role.toLowerCase()) {
    case 'admin':
    case 'super admin':
      _go(const AdminDashboard());
      break;

    case 'employee':
      _go(EmployeeDashboardScreen(
        currentUserId: uid,
        currentUserRole: role,
      ));
      break;

    case 'intern':
      _go(InternDashboardScreen(
        currentUserId: uid,
        currentUserRole: role,
      ));
      break;

    default:
      _go(const UserLoginScreen());
  }
}


  void _go(Widget page) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }


  double _getResponsiveSize(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width < 600) return 150; // mobile
    if (width < 1024) return 200; // tablet
    return 250; // desktop
  }

  @override
  Widget build(BuildContext context) {
    double imageSize = _getResponsiveSize(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: ScaleTransition(
            scale: _animation,
            child: Image.asset(
              'assets/logo.png', // 👈 Replace with your image path
              width: imageSize,
              height: imageSize,
            ),
          ),
        ),
      ),
    );
  }
}
