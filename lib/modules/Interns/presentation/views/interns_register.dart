import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:task_management_application/utils/common/pop_up_screen.dart';
import 'package:uuid/uuid.dart';

class InternRegistration extends StatefulWidget {
  final String currentUserId;
  final String currentUserRole;

  const InternRegistration({
    super.key,
    required this.currentUserId,
    required this.currentUserRole,
  });

  @override
  State<InternRegistration> createState() => _InternRegistrationState();
}

class _InternRegistrationState extends State<InternRegistration> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _altPhoneController = TextEditingController(); // ✅ New
  final _aadharController = TextEditingController(); // ✅ New
  final _panController = TextEditingController(); // ✅ New
  final _collegeController = TextEditingController();
  final _courseController = TextEditingController();
  final _passwordController = TextEditingController();
  final _permanentAddressController = TextEditingController();
  final _currentAddressController = TextEditingController();
  final _zipcodeController = TextEditingController();

  // Dropdown selections
  String? selectedGender;
  String? selectedDepartment;
  String? selectedDepartmentId;
  String? selectedCountry;
  String? selectedState;
  String? selectedCity;

  DateTime? startDate;
  DateTime? endDate;
  String? duration;

  final List<String> genders = ['Male', 'Female', 'Other'];
  final List<String> countries = ['India', 'USA', 'UK', 'Canada', 'Australia'];

  bool isLoading = false;
  bool obscurePassword = true;

  List<Map<String, String>> departments = [];
  bool isLoadingDepartments = true;

  final Map<String, List<String>> stateCityMap = {
    'Maharashtra': ['Mumbai', 'Pune', 'Nagpur', 'Nashik'],
    'Karnataka': ['Bengaluru', 'Mysuru', 'Mangalore', 'Hubballi'],
    'Tamil Nadu': ['Chennai', 'Coimbatore', 'Madurai', 'Salem'],
    'Gujarat': ['Ahmedabad', 'Surat', 'Vadodara', 'Rajkot'],
    'Delhi': ['New Delhi', 'Dwarka', 'Rohini', 'Saket'],
    'Uttar Pradesh': ['Lucknow', 'Kanpur', 'Noida', 'Varanasi'],
  };

  List<String> cityList = [];

  final LinearGradient gradient = const LinearGradient(
    colors: [
      Color(0xFF34D0C6),
      Color(0xFF22A4E0),
      Color(0xFF1565C0),
    ],
  );

  @override
  void initState() {
    super.initState();
    fetchDepartments();
  }

  Future<void> fetchDepartments() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('departments').get();

      final deptList = snapshot.docs.map((doc) {
        return {
          'dept_id': doc['dept_id'] as String,
          'dept_name': doc['dept_name'] as String,
        };
      }).toList();

      setState(() {
        departments = deptList;
        isLoadingDepartments = false;
      });
    } catch (e) {
      debugPrint("Error fetching departments: $e");
      setState(() => isLoadingDepartments = false);
    }
  }

  Future<void> saveIntern() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedDepartment == null ||
        selectedGender == null ||
        selectedCountry == null ||
        selectedState == null ||
        selectedCity == null ||
        startDate == null ||
        endDate == null) {
      showCustomAlert(
        context,
        isSuccess: false,
        title: 'Missing Fields',
        description: 'Please fill all required fields before submitting.',
      );
      return;
    }

    final months = (endDate!.difference(startDate!).inDays / 30).floor();
    duration = "$months months";

    setState(() => isLoading = true);

    try {
      final internId = const Uuid().v4();
      final password = _passwordController.text.trim();

      await FirebaseFirestore.instance.collection('interns').doc(internId).set({
        'intern_id': internId,
        'intern_name': _nameController.text.trim(),
        'intern_email': _emailController.text.trim(),
        'intern_phone': _phoneController.text.trim(),
        'intern_alt_phone': _altPhoneController.text.trim(), // ✅ New
        'intern_aadhar_no': _aadharController.text.trim(), // ✅ New
        'intern_pan_no': _panController.text.trim(), // ✅ New
        'intern_dept': selectedDepartment,
        'intern_dept_id': selectedDepartmentId,
        'intern_college': _collegeController.text.trim(),
        'intern_course': _courseController.text.trim(),
        'intern_gender': selectedGender,
        'intern_start_date': startDate,
        'intern_end_date': endDate,
        'intern_duration': duration,
        'intern_permanent_address': _permanentAddressController.text.trim(),
        'intern_current_address': _currentAddressController.text.trim(),
        'intern_city': selectedCity,
        'intern_state': selectedState,
        'intern_zipcode': _zipcodeController.text.trim(),
        'intern_country': selectedCountry,
        'intern_password': password,
        'user_ref': '/users/$internId',
      });

      await FirebaseFirestore.instance.collection('users').doc(internId).set({
        'user_id': internId,
        'user_name': _nameController.text.trim(),
        'user_email': _emailController.text.trim(),
        'user_password': password,
        'role': 'intern',
        'created_at': FieldValue.serverTimestamp(),
      });

      _clearForm();

      showCustomAlert(
        context,
        isSuccess: true,
        title: 'Success',
        description: 'Intern registered successfully!',
      );
    } catch (e) {
      debugPrint("Error saving intern: $e");
      setState(() => isLoading = false);
      showCustomAlert(
        context,
        isSuccess: false,
        title: 'Error',
        description: 'Failed to register intern: $e',
      );
    }
  }

  void _clearForm() {
    setState(() {
      _nameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _altPhoneController.clear(); // ✅ New
      _aadharController.clear(); // ✅ New
      _panController.clear(); // ✅ New
      _collegeController.clear();
      _courseController.clear();
      _passwordController.clear();
      _permanentAddressController.clear();
      _currentAddressController.clear();
      _zipcodeController.clear();
      selectedDepartment = null;
      selectedDepartmentId = null;
      selectedGender = null;
      selectedCountry = null;
      selectedState = null;
      selectedCity = null;
      cityList = [];
      startDate = null;
      endDate = null;
      duration = null;
      isLoading = false;
    });
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

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(title,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
      );

  Widget _buildForm(double width) {
    return Form(
      key: _formKey,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: Column(
          children: [
            ShaderMask(
              shaderCallback: (bounds) =>
                  gradient.createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
              child: const Text("Intern Registration",
                  style: TextStyle(
                      fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            const SizedBox(height: 25),

            _sectionTitle("Basic Details"),

            gradientBorderWrapper(
              child: TextFormField(
                controller: _nameController,
                decoration: _inputDecoration("Full Name"),
                validator: (v) => v!.isEmpty ? "Enter intern name" : null,
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

            // ✅ New Alternate Phone, Aadhar, PAN fields
            gradientBorderWrapper(
              child: TextFormField(
                controller: _altPhoneController,
                decoration: _inputDecoration("Alternate Phone Number"),
              ),
            ),
            const SizedBox(height: 15),

            gradientBorderWrapper(
              child: TextFormField(
                controller: _aadharController,
                decoration: _inputDecoration("Aadhar Number"),
              ),
            ),
            const SizedBox(height: 15),

            gradientBorderWrapper(
              child: TextFormField(
                controller: _panController,
                decoration: _inputDecoration("PAN Number"),
              ),
            ),
            const SizedBox(height: 15),


            gradientBorderWrapper(
              child: DropdownButtonFormField<String>(
                value: selectedGender,
                decoration: _inputDecoration("Select Gender"),
                items: genders
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (val) => setState(() => selectedGender = val),
                validator: (val) => val == null ? "Select gender" : null,
              ),
            ),
            const SizedBox(height: 20),

            _sectionTitle("Internship Information"),

            gradientBorderWrapper(
              child: TextFormField(
                controller: _collegeController,
                decoration: _inputDecoration("College / University"),
                validator: (v) => v!.isEmpty ? "Enter college name" : null,
              ),
            ),
            const SizedBox(height: 15),

            gradientBorderWrapper(
              child: TextFormField(
                controller: _courseController,
                decoration: _inputDecoration("Course / Degree"),
                validator: (v) => v!.isEmpty ? "Enter course name" : null,
              ),
            ),
            const SizedBox(height: 15),

            // Department Dropdown
            gradientBorderWrapper(
              child: isLoadingDepartments
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child:
                          Center(child: CircularProgressIndicator(color: Color(0xFF1565C0))),
                    )
                  : DropdownButtonFormField<String>(
                      value: selectedDepartment,
                      decoration: _inputDecoration("Select Department"),
                      items: departments
                          .map((d) => DropdownMenuItem<String>(
                                value: d['dept_name'],
                                child: Text(d['dept_name'] ?? ''),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedDepartment = val;
                          selectedDepartmentId = departments
                              .firstWhere((d) => d['dept_name'] == val)['dept_id'];
                        });
                      },
                      validator: (val) => val == null ? "Select department" : null,
                    ),
            ),
            const SizedBox(height: 15),

            gradientBorderWrapper(
              child: ListTile(
                title: Text(
                  startDate == null
                      ? "Select Internship Start Date"
                      : "Start Date: ${startDate!.toLocal().toString().split(' ')[0]}",
                  style: const TextStyle(color: Colors.black54),
                ),
                trailing: const Icon(Icons.calendar_today, color: Color(0xFF1565C0)),
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => startDate = picked);
                },
              ),
            ),
            const SizedBox(height: 15),

            gradientBorderWrapper(
              child: ListTile(
                title: Text(
                  endDate == null
                      ? "Select Internship End Date"
                      : "End Date: ${endDate!.toLocal().toString().split(' ')[0]}",
                  style: const TextStyle(color: Colors.black54),
                ),
                trailing: const Icon(Icons.calendar_today, color: Color(0xFF1565C0)),
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: startDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => endDate = picked);
                },
              ),
            ),
            const SizedBox(height: 20),

            _sectionTitle("Address Details"),

            gradientBorderWrapper(
              child: TextFormField(
                controller: _permanentAddressController,
                decoration: _inputDecoration("Permanent Address"),
                validator: (v) => v!.isEmpty ? "Enter permanent address" : null,
              ),
            ),
            const SizedBox(height: 15),

            gradientBorderWrapper(
              child: TextFormField(
                controller: _currentAddressController,
                decoration: _inputDecoration("Current Address"),
              ),
            ),
            const SizedBox(height: 15),

            // State Dropdown
            gradientBorderWrapper(
              child: DropdownButtonFormField<String>(
                value: selectedState,
                decoration: _inputDecoration("Select State"),
                items: stateCityMap.keys
                    .map((state) =>
                        DropdownMenuItem(value: state, child: Text(state)))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    selectedState = val;
                    selectedCity = null;
                    cityList = val != null ? stateCityMap[val]! : [];
                  });
                },
                validator: (val) => val == null ? "Select state" : null,
              ),
            ),
            const SizedBox(height: 15),

            // City Dropdown
            gradientBorderWrapper(
              child: DropdownButtonFormField<String>(
                value: selectedCity,
                decoration: _inputDecoration("Select City"),
                items: cityList
                    .map((city) =>
                        DropdownMenuItem(value: city, child: Text(city)))
                    .toList(),
                onChanged: (val) => setState(() => selectedCity = val),
                validator: (val) => val == null ? "Select city" : null,
              ),
            ),
            const SizedBox(height: 15),

            gradientBorderWrapper(
              child: TextFormField(
                controller: _zipcodeController,
                decoration: _inputDecoration("Zip / Postal Code"),
              ),
            ),
            const SizedBox(height: 15),

            gradientBorderWrapper(
              child: DropdownButtonFormField<String>(
                value: selectedCountry,
                decoration: _inputDecoration("Select Country"),
                items: countries
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) => setState(() => selectedCountry = val),
                validator: (val) => val == null ? "Select country" : null,
              ),
            ),
            const SizedBox(height: 20),

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
                    onPressed: () =>
                        setState(() => obscurePassword = !obscurePassword),
                  ),
                ),
                validator: (v) => v!.isEmpty ? "Enter password" : null,
              ),
            ),
            const SizedBox(height: 30),

            GestureDetector(
              onTap: isLoading ? null : saveIntern,
              child: Container(
                width: double.infinity,
                height: 55,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(15),
                ),
                alignment: Alignment.center,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Submit",
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
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 800;
    final double formWidth = isDesktop ? 500 : double.infinity;

    return Scaffold(
      body: Column(children: [
        Container(
          height: kToolbarHeight + 10,
          decoration: BoxDecoration(gradient: gradient, boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))
          ]),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 25),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: _buildForm(formWidth),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
