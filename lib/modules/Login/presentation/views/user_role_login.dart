import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:task_management_application/modules/Admin/presentation/views/super_admin/admin_dashboard.dart';
import 'package:task_management_application/modules/Employee/presentation/views/employee_dashboard.dart';
import 'package:task_management_application/modules/Interns/presentation/views/intern_dashboard.dart';
import 'package:task_management_application/utils/common/appbar_drawer.dart';
import 'package:task_management_application/utils/common/pop_up_screen.dart';
import 'package:task_management_application/utils/common/user_session.dart';

class UserLoginScreen extends StatefulWidget {
  const UserLoginScreen({super.key});

  @override
  State<UserLoginScreen> createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends State<UserLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false; // 👁️ Add eye toggle state

  Widget getNextScreen(String role, DocumentSnapshot userDoc) {
    final userId = userDoc['user_id'] ?? '';
    final userRole = userDoc['role'] ?? '';

    switch (role.toLowerCase()) {
      case 'admin':
        return const AdminDashboard();

      case 'super admin':
        return CommonScaffold(
          title: "Super Admin Dashboard",
          role: 'super admin',
          body: const Center(child: Text("Super Admin Dashboard")),
        );

      case 'employee':
        return EmployeeDashboardScreen(
          currentUserId: userId,
          currentUserRole: userRole,
        );

      case 'intern':
        return InternDashboardScreen(
          currentUserId: userId,
          currentUserRole: userRole,
        );

      default:
        return CommonScaffold(
          title: "Unknown Role",
          role: 'unknown',
          body: const Center(child: Text("Invalid Role")),
        );
    }
  }

  // 🔥 FORGOT PASSWORD — update password in correct table
  Future<void> _showForgotPasswordDialog() async {
    final newPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text("Reset Password"),
          content: TextField(
            controller: newPasswordController,
            decoration: const InputDecoration(
                labelText: "Enter New Password"
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text("Update"),
              onPressed: () async {
                final email = _emailController.text.trim();
                final newPassword = newPasswordController.text.trim();

                if (email.isEmpty || newPassword.isEmpty) {
                  showCustomAlert(
                    context,
                    isSuccess: false,
                    title: "Missing Fields",
                    description: "Enter email & new password.",
                  );
                  return;
                }

                Navigator.pop(context);
                await _updatePassword(email, newPassword);
              },
            ),
          ],
        );
      },
    );
  }

  // 🔥 Update password from all possible collections
  Future<void> _updatePassword(String email, String newPassword) async {
    final collections = ["users", "employee", "interns", "admin"];
    bool updated = false;

    for (var col in collections) {
      final snap = await FirebaseFirestore.instance
          .collection(col)
          .where('user_email', isEqualTo: email)
          .get();

      if (snap.docs.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection(col)
            .doc(snap.docs.first.id)
            .update({'user_password': newPassword});

        updated = true;
        break;
      }
    }

    if (updated) {
      showCustomAlert(
        context,
        isSuccess: true,
        title: "Password Updated",
        description: "Password updated successfully for $email",
      );
    } else {
      showCustomAlert(
        context,
        isSuccess: false,
        title: "Error",
        description: "Email not found in system.",
      );
    }
  }

  Future<void> _loginUser(BuildContext context) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showCustomAlert(
        context,
        isSuccess: false,
        title: "Missing Fields",
        description: "Please enter both email and password.",
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('user_email', isEqualTo: email)
          .where('user_password', isEqualTo: password)
          .get();

      if (snapshot.docs.isEmpty) {
        showCustomAlert(
          context,
          isSuccess: false,
          title: "Login Failed",
          description: "Invalid email or password.",
        );
        setState(() => _isLoading = false);
        return;
      }

      final userDoc = snapshot.docs.first;
      final role = userDoc['role'] ?? '';
      final name = userDoc['user_name'] ?? '';
      final userId = userDoc['user_id'] ?? '';
      final userEmail = userDoc['user_email'] ?? '';

     UserSession().setUser(
  id: userId,
  userRole: role,
  userName: name,
  userEmail: userEmail,
);

showCustomAlert(
  context,
  isSuccess: true,
  title: "Login Successful",
  description: "Welcome back, $name!",
  nextScreen: getNextScreen(role, userDoc),
);

    } catch (e) {
      showCustomAlert(
        context,
        isSuccess: false,
        title: "Login Error",
        description: e.toString(),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: AssetImage('assets/logo.png'),
            ),
          ),
        ],
        flexibleSpace: Container(
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
          ),
        ),
        elevation: 4,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isDesktop = constraints.maxWidth > 800;
          return Center(
            child: Container(
              width: isDesktop ? 400 : double.infinity,
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 10)
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        Color(0xFF34D0C6),
                        Color(0xFF22A4E0),
                        Color(0xFF1565C0)
                      ],
                    ).createShader(bounds),
                    child: const Text(
                      "Login",
                      style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 30),

                  _buildGradientTextField("Email", Icons.email, _emailController),

                  const SizedBox(height: 20),

                  _buildPasswordField(),  // 👁️ UPDATED PASSWORD FIELD

                  const SizedBox(height: 12),

                  // 🔹 Forgot Password (right aligned)
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: _showForgotPasswordDialog,
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(
                            color: Color(0xFF1565C0),
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  _isLoading
                      ? const CircularProgressIndicator()
                      : GestureDetector(
                          onTap: () => _loginUser(context),
                          child: Container(
                            height: 50,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF34D0C6),
                                  Color(0xFF22A4E0),
                                  Color(0xFF1565C0)
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              "Login",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 🔹 Password field with eye icon
  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF34D0C6),
            Color(0xFF22A4E0),
            Color(0xFF1565C0)
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(1.5),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
            hintText: "Password",
            prefixIcon: const Icon(Icons.lock, color: Color(0xFF1565C0)),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 15, horizontal: 10),

            // 👁️ Eye Icon
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: const Color(0xFF1565C0),
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientTextField(
      String hint, IconData icon, TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF34D0C6),
            Color(0xFF22A4E0),
            Color(0xFF1565C0)
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(1.5),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFF1565C0)),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          ),
        ),
      ),
    );
  }
}
