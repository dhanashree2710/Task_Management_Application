// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:task_management_application/utils/common/appbar_drawer.dart';
// import 'package:task_management_application/utils/common/pop_up_screen.dart';
// import 'package:uuid/uuid.dart';

// class UserRoleRegistration extends StatefulWidget {
//   final String currentUserRole; // ✅ Pass role of logged-in user

//   const UserRoleRegistration({super.key, required this.currentUserRole});

//   @override
//   State<UserRoleRegistration> createState() => _UserRoleRegistrationState();
// }

// class _UserRoleRegistrationState extends State<UserRoleRegistration> {
//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();

//   String? selectedRole;
//   final List<String> roles = ['admin', 'super admin', 'employee', 'intern'];

//   final _formKey = GlobalKey<FormState>();
//   bool isLoading = false;

//   final LinearGradient gradient = const LinearGradient(
//     colors: [
//       Color(0xFF34D0C6),
//       Color(0xFF22A4E0),
//       Color(0xFF1565C0),
//     ],
//   );

//   // ✅ Firebase save function
//   Future<void> saveUser() async {
//     if (!_formKey.currentState!.validate()) return;
//     if (selectedRole == null) {
//       showCustomAlert(
//         context,
//         isSuccess: false,
//         title: 'Missing Role',
//         description: 'Please select a role before submitting.',
//       );
//       return;
//     }

//     setState(() => isLoading = true);

//     try {
//       final userId = const Uuid().v4();
//       final createdAt = DateTime.now().toIso8601String();

//       await FirebaseFirestore.instance.collection('users').doc(userId).set({
//         'user_id': userId,
//         'user_name': _nameController.text.trim(),
//         'user_email': _emailController.text.trim(),
//         'user_password': _passwordController.text.trim(),
//         'role': selectedRole,
//         'created_at': createdAt,
//       });

//       setState(() {
//         _nameController.clear();
//         _emailController.clear();
//         _passwordController.clear();
//         selectedRole = null;
//         isLoading = false;
//       });

//       showCustomAlert(
//         context,
//         isSuccess: true,
//         title: 'Success',
//         description: 'User added successfully!',
//       );
//     } catch (e) {
//       setState(() => isLoading = false);
//       showCustomAlert(
//         context,
//         isSuccess: false,
//         title: 'Error',
//         description: 'Failed to add user: $e',
//       );
//     }
//   }

//   // ✅ Input field decoration
//   InputDecoration _inputDecoration(String label) {
//     return InputDecoration(
//       hintText: label,
//       filled: true,
//       fillColor: Colors.white,
//       hintStyle: const TextStyle(color: Colors.black54),
//       contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(15),
//         borderSide: BorderSide.none,
//       ),
//     );
//   }

//   Widget gradientBorderWrapper({required Widget child}) {
//     return Container(
//       decoration: BoxDecoration(
//         gradient: gradient,
//         borderRadius: BorderRadius.circular(18),
//       ),
//       padding: const EdgeInsets.all(2),
//       child: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(15),
//         ),
//         child: child,
//       ),
//     );
//   }

//   Widget _buildForm(double width) {
//     return Form(
//       key: _formKey,
//       child: ConstrainedBox(
//         constraints: BoxConstraints(maxWidth: width),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             ShaderMask(
//               shaderCallback: (bounds) => const LinearGradient(
//                 colors: [
//                   Color(0xFF34D0C6),
//                   Color(0xFF22A4E0),
//                   Color(0xFF1565C0),
//                 ],
//               ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
//               child: const Text(
//                 "Add User",
//                 style: TextStyle(
//                   fontSize: 26,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 30),

//             // Name
//             gradientBorderWrapper(
//               child: TextFormField(
//                 controller: _nameController,
//                 decoration: _inputDecoration("Enter user name"),
//                 validator: (value) =>
//                     value!.isEmpty ? 'Enter user name' : null,
//               ),
//             ),
//             const SizedBox(height: 20),

//             // Email
//             gradientBorderWrapper(
//               child: TextFormField(
//                 controller: _emailController,
//                 decoration: _inputDecoration("Enter user email"),
//                 validator: (value) =>
//                     value!.isEmpty ? 'Enter user email' : null,
//               ),
//             ),
//             const SizedBox(height: 20),

//             // Password
//             gradientBorderWrapper(
//               child: TextFormField(
//                 controller: _passwordController,
//                 obscureText: true,
//                 decoration: _inputDecoration("Enter password"),
//                 validator: (value) =>
//                     value!.isEmpty ? 'Enter password' : null,
//               ),
//             ),
//             const SizedBox(height: 20),

//             // Role dropdown
//             gradientBorderWrapper(
//               child: DropdownButtonFormField<String>(
//                 value: selectedRole,
//                 decoration: _inputDecoration("Select Role"),
//                 items: roles
//                     .map((role) => DropdownMenuItem(
//                           value: role,
//                           child: Text(role),
//                         ))
//                     .toList(),
//                 onChanged: (value) => setState(() => selectedRole = value),
//                 validator: (value) => value == null ? 'Select a role' : null,
//               ),
//             ),
//             const SizedBox(height: 30),

//             // Submit button
//             GestureDetector(
//               onTap: isLoading ? null : saveUser,
//               child: Container(
//                 width: double.infinity,
//                 height: 55,
//                 decoration: BoxDecoration(
//                   gradient: gradient,
//                   borderRadius: BorderRadius.circular(15),
//                 ),
//                 alignment: Alignment.center,
//                 child: isLoading
//                     ? const CircularProgressIndicator(color: Colors.white)
//                     : const Text(
//                         "Submit",
//                         style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold),
//                       ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final bool isDesktop = MediaQuery.of(context).size.width >= 800;
//     final double formWidth = isDesktop ? 400 : double.infinity;

//     // ✅ Restrict access only to admin or super admin
//     if (widget.currentUserRole != 'admin' &&
//         widget.currentUserRole != 'super admin') {
//       return const Scaffold(
//         body: Center(
//           child: Text(
//             'Access Denied\nOnly Admins can access this screen.',
//             textAlign: TextAlign.center,
//             style: TextStyle(fontSize: 18, color: Colors.red),
//           ),
//         ),
//       );
//     }

//     return CommonScaffold(
//       title: "",
//       role: widget.currentUserRole, // ✅ Pass role dynamically
//       body: Center(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 25),
//           child: _buildForm(formWidth),
//         ),
//       ),
//     );
//   }
// }


