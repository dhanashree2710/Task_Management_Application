import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:task_management_application/utils/common/pop_up_screen.dart';
import 'package:uuid/uuid.dart';

class AdminRegistration extends StatefulWidget {
  final String currentUserId;
  final String currentUserRole;

  const AdminRegistration({
    super.key,
    required this.currentUserId,
    required this.currentUserRole,
  });

  @override
  State<AdminRegistration> createState() => _AdminRegistrationState();
}

class _AdminRegistrationState extends State<AdminRegistration> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  String? selectedRole;
  String? selectedStatus;

  bool isLoading = false;
  bool obscurePassword = true;

  final List<String> roles = ['Admin', 'Super Admin', 'Employee', 'Intern'];
  final List<String> statuses = ['Active', 'Inactive'];

  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  final LinearGradient gradient = const LinearGradient(
    colors: [Color(0xFF34D0C6), Color(0xFF22A4E0), Color(0xFF1565C0)],
  );
  @override
  void dispose() {
    _verticalController.dispose();
    super.dispose();
  }

  Future<void> saveAdmin() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedRole == null || selectedStatus == null) {
      showCustomAlert(
        context,
        isSuccess: false,
        title: 'Missing Fields',
        description: 'Please fill all required fields before submitting.',
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final userId = const Uuid().v4();
      final password = _passwordController.text.trim();

      final roleKey = selectedRole!.toLowerCase().replaceAll(
        " ",
        "_",
      ); // admin / super_admin

      /// 🔹 ALWAYS save in USERS
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'user_id': userId,
        'user_email': _emailController.text.trim(),
        'user_password': password,
        'user_name': _nameController.text.trim(),
        'role': roleKey,
        'created_at': FieldValue.serverTimestamp(),
      });

      /// 🔹 ONLY if role == Admin → save in ADMINS
      if (roleKey == 'admin') {
        await FirebaseFirestore.instance.collection('admins').doc(userId).set({
          'admin_id': userId,
          'admin_name': _nameController.text.trim(),
          'admin_email': _emailController.text.trim(),
          'admin_phone': _phoneController.text.trim(),
          'admin_role': selectedRole,
          'admin_status': selectedStatus,
          'created_at': FieldValue.serverTimestamp(),
          'user_ref': '/users/$userId',
        });
      }

      _clearForm();

      showCustomAlert(
        context,
        isSuccess: true,
        title: 'Success',
        description: 'User registered successfully!',
      );
    } catch (e) {
      setState(() => isLoading = false);
      showCustomAlert(
        context,
        isSuccess: false,
        title: 'Error',
        description: 'Failed to register user: $e',
      );
    }
  }

  void _clearForm() {
    setState(() {
      _nameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _passwordController.clear();
      selectedRole = null;
      selectedStatus = null;
      isLoading = false;
    });
  }

  InputDecoration _inputDecoration(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      hintStyle: const TextStyle(color: Colors.black54),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      suffixIcon: suffixIcon,
    );
  }

  Widget gradientBorderWrapper({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(2),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: child,
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    ),
  );

  Widget _buildForm(double width) {
    return Form(
      key: _formKey,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: Column(
          children: [
            ShaderMask(
              shaderCallback:
                  (bounds) => gradient.createShader(
                    Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                  ),
              child: const Text(
                "User Registration",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 25),

            _sectionTitle("Details"),

            gradientBorderWrapper(
              child: TextFormField(
                controller: _nameController,
                decoration: _inputDecoration("Full Name"),
                validator: (v) => v!.isEmpty ? "Enter name" : null,
              ),
            ),
            const SizedBox(height: 15),

            gradientBorderWrapper(
              child: TextFormField(
                controller: _emailController,
                decoration: _inputDecoration("Email"),
                validator: (v) => v!.isEmpty ? "Enter email" : null,
              ),
            ),
            const SizedBox(height: 15),

            gradientBorderWrapper(
              child: TextFormField(
                controller: _phoneController,
                decoration: _inputDecoration("Phone Number"),
                validator: (v) => v!.isEmpty ? "Enter phone number" : null,
              ),
            ),
            const SizedBox(height: 15),

            // Role Dropdown
            gradientBorderWrapper(
              child: DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: _inputDecoration("Select Role"),
                items:
                    roles
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                onChanged: (val) => setState(() => selectedRole = val),
                validator: (val) => val == null ? "Select role" : null,
              ),
            ),
            const SizedBox(height: 15),

            // Status Dropdown
            gradientBorderWrapper(
              child: DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: _inputDecoration("Select Status"),
                items:
                    statuses
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                onChanged: (val) => setState(() => selectedStatus = val),
                validator: (val) => val == null ? "Select status" : null,
              ),
            ),
            const SizedBox(height: 15),

            _sectionTitle("Login Credentials"),

            gradientBorderWrapper(
              child: TextFormField(
                controller: _passwordController,
                obscureText: obscurePassword,
                decoration: _inputDecoration(
                  "Enter Password",
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: const Color(0xFF1565C0),
                    ),
                    onPressed:
                        () =>
                            setState(() => obscurePassword = !obscurePassword),
                  ),
                ),
                validator: (v) => v!.isEmpty ? "Enter password" : null,
              ),
            ),
            const SizedBox(height: 30),

            GestureDetector(
              onTap: isLoading ? null : saveAdmin,
              child: Container(
                width: double.infinity,
                height: 55,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(15),
                ),
                alignment: Alignment.center,
                child:
                    isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                          "Submit",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 800;
    final double formWidth = isDesktop ? 450 : double.infinity;

    return Scaffold(
      body: Column(
        children: [
          Container(
            height: kToolbarHeight + 10,
            decoration: BoxDecoration(
              gradient: gradient,
              boxShadow: const [
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
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
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
          Expanded(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.trackpad,
                  PointerDeviceKind.touch,
                },
                scrollbars: false, // ✅ IMPORTANT
              ),
              child: SingleChildScrollView(
                primary: true, // ✅ THIS FIXES EVERYTHING
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 25,
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: _buildForm(formWidth),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
