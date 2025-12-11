import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_management_application/modules/Interns/presentation/views/interns_register.dart';

class InternListScreen extends StatefulWidget {
  final String currentUserId;
  final String currentUserRole;

  const InternListScreen({
    super.key,
    required this.currentUserId,
    required this.currentUserRole,
  });

  @override
  State<InternListScreen> createState() => _InternListScreenState();
}

class _InternListScreenState extends State<InternListScreen> {
  final TextEditingController _filterController = TextEditingController();
  final ScrollController _horizontalScroll = ScrollController();

  List<DocumentSnapshot> _interns = [];
  List<DocumentSnapshot> _filteredInterns = [];
  bool _isLoading = true;
  String? _editingInternId;

  // controllers
  final Map<String, TextEditingController> _nameCtrls = {};
  final Map<String, TextEditingController> _emailCtrls = {};
  final Map<String, TextEditingController> _phoneCtrls = {};
  final Map<String, TextEditingController> _collegeCtrls = {};
  final Map<String, TextEditingController> _courseCtrls = {};
  final Map<String, TextEditingController> _deptCtrls = {};
  final Map<String, TextEditingController> _permanentAddrCtrls = {};
  final Map<String, TextEditingController> _currentAddrCtrls = {};
  final Map<String, TextEditingController> _zipcodeCtrls = {};
  final Map<String, TextEditingController> _passwordCtrls = {};
  final Map<String, TextEditingController> _durationCtrls = {};
  final Map<String, TextEditingController> _altPhoneCtrls = {};
final Map<String, TextEditingController> _aadharCtrls = {};
final Map<String, TextEditingController> _panCtrls = {};


  // dropdown values
  final Map<String, String> _genderValues = {};
  final Map<String, String> _cityValues = {};
  final Map<String, String> _stateValues = {};
  final Map<String, String> _countryValues = {};
  final Map<String, DateTime> _startDateValues = {};
  final Map<String, DateTime> _endDateValues = {};

  // static options
  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _countries = ['India', 'USA', 'UK', 'Canada', 'Australia'];
  final List<String> _states = [
    'Maharashtra',
    'Delhi',
    'Karnataka',
    'Tamil Nadu',
    'West Bengal',
    'Telangana',
    'Gujarat'
  ];
  final List<String> _cities = [
    'Pune',
    'Mumbai',
    'Nagpur',
    'Nashik',
    'Bengaluru',
    'Chennai',
    'Ahmedabad',
    'Delhi'
  ];

  @override
  void initState() {
    super.initState();
    fetchInterns();
  }

  Future<void> fetchInterns() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance.collection('interns').get();
      setState(() {
        _interns = snapshot.docs;
        _filteredInterns = _interns;
        _isLoading = false;
      });

      for (var doc in _interns) {
        final id = doc.id;
        final data = doc.data() as Map<String, dynamic>;

        _nameCtrls.putIfAbsent(id, () => TextEditingController(text: (data['intern_name'] ?? '').toString()));
        _emailCtrls.putIfAbsent(id, () => TextEditingController(text: (data['intern_email'] ?? '').toString()));
        _phoneCtrls.putIfAbsent(id, () => TextEditingController(text: (data['intern_phone'] ?? '').toString()));
        _collegeCtrls.putIfAbsent(id, () => TextEditingController(text: (data['intern_college'] ?? '').toString()));
        _courseCtrls.putIfAbsent(id, () => TextEditingController(text: (data['intern_course'] ?? '').toString()));
        _deptCtrls.putIfAbsent(id, () => TextEditingController(text: (data['intern_dept'] ?? '').toString()));
        _permanentAddrCtrls.putIfAbsent(id, () => TextEditingController(text: (data['intern_permanent_address'] ?? '').toString()));
        _currentAddrCtrls.putIfAbsent(id, () => TextEditingController(text: (data['intern_current_address'] ?? '').toString()));
        _zipcodeCtrls.putIfAbsent(id, () => TextEditingController(text: (data['intern_zipcode'] ?? '').toString()));
        _passwordCtrls.putIfAbsent(id, () => TextEditingController(text: (data['intern_password'] ?? '').toString()));
        _durationCtrls.putIfAbsent(id, () => TextEditingController(text: (data['intern_duration'] ?? '').toString()));
_altPhoneCtrls.putIfAbsent(id, () => TextEditingController(text: (data['intern_alt_phone'] ?? '').toString()));
_aadharCtrls.putIfAbsent(id, () => TextEditingController(text: (data['intern_aadhar_no'] ?? '').toString()));
_panCtrls.putIfAbsent(id, () => TextEditingController(text: (data['intern_pan_no'] ?? '').toString()));

        _genderValues.putIfAbsent(id, () => (data['intern_gender'] ?? _genders.first).toString());
        _cityValues.putIfAbsent(id, () => (data['intern_city'] ?? _cities.first).toString());
        _stateValues.putIfAbsent(id, () => (data['intern_state'] ?? _states.first).toString());
        _countryValues.putIfAbsent(id, () => (data['intern_country'] ?? _countries.first).toString());

        if (data['intern_start_date'] is Timestamp) {
          _startDateValues[id] = (data['intern_start_date'] as Timestamp).toDate();
        }
        if (data['intern_end_date'] is Timestamp) {
          _endDateValues[id] = (data['intern_end_date'] as Timestamp).toDate();
        }
      }
    } catch (e) {
      debugPrint("Error fetching interns: $e");
      setState(() => _isLoading = false);
    }
  }

  void filterInterns(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredInterns = _interns;
      } else {
        _filteredInterns = _interns.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final fields = [
            data['intern_name']?.toString().toLowerCase() ?? '',
            data['intern_email']?.toString().toLowerCase() ?? '',
            data['intern_phone']?.toString().toLowerCase() ?? '',
            data['intern_college']?.toString().toLowerCase() ?? '',
            data['intern_dept']?.toString().toLowerCase() ?? '',
          ];
          return fields.any((f) => f.contains(query.toLowerCase()));
        }).toList();
      }
    });
  }

  Future<void> _saveRowEdits(String docId) async {
    final updated = <String, dynamic>{
      'intern_name': _nameCtrls[docId]?.text ?? '',
      'intern_email': _emailCtrls[docId]?.text ?? '',
      'intern_phone': _phoneCtrls[docId]?.text ?? '',
      'intern_college': _collegeCtrls[docId]?.text ?? '',
      'intern_course': _courseCtrls[docId]?.text ?? '',
      'intern_dept': _deptCtrls[docId]?.text ?? '',
      'intern_duration': _durationCtrls[docId]?.text ?? '',
      'intern_permanent_address': _permanentAddrCtrls[docId]?.text ?? '',
      'intern_current_address': _currentAddrCtrls[docId]?.text ?? '',
      'intern_zipcode': _zipcodeCtrls[docId]?.text ?? '',
      'intern_password': _passwordCtrls[docId]?.text ?? '',
      'intern_gender': _genderValues[docId] ?? '',
      'intern_city': _cityValues[docId] ?? '',
      'intern_state': _stateValues[docId] ?? '',
      'intern_country': _countryValues[docId] ?? '',
      'intern_start_date': _startDateValues[docId],
      'intern_end_date': _endDateValues[docId],
      'intern_alt_phone': _altPhoneCtrls[docId]?.text ?? '',
'intern_aadhar_no': _aadharCtrls[docId]?.text ?? '',
'intern_pan_no': _panCtrls[docId]?.text ?? '',

    };

    try {
      await FirebaseFirestore.instance.collection('interns').doc(docId).update(updated);
      await fetchInterns();
      setState(() => _editingInternId = null);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Intern updated")));
    } catch (e) {
      debugPrint("Error updating intern: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Update failed: $e")));
    }
  }

  Future<void> _deleteIntern(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this intern?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("No")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes")),
        ],
      ),
    );
    if (ok == true) {
      await FirebaseFirestore.instance.collection('interns').doc(id).delete();
      await fetchInterns();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Intern deleted")));
    }
  }

  Widget _buildInternTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Scrollbar(
        controller: _horizontalScroll,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _horizontalScroll,
          scrollDirection: Axis.horizontal,
          child: DataTable(
            border: TableBorder.all(color: Colors.grey.shade300),
            headingRowColor: MaterialStateProperty.all(const Color(0xFF076AB1)),
            headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            columns: const [
              DataColumn(label: Text("Name")),
              DataColumn(label: Text("Email")),
              DataColumn(label: Text("Phone")),
              DataColumn(label: Text("Alt. Phone")),
              DataColumn(label: Text("College")),
              DataColumn(label: Text("Course")),
              DataColumn(label: Text("Department")),
              DataColumn(label: Text("Duration")),
              DataColumn(label: Text("Gender")),
              DataColumn(label: Text("City")),
              DataColumn(label: Text("State")),
              DataColumn(label: Text("Country")),
              DataColumn(label: Text("Start Date")),
              DataColumn(label: Text("End Date")),
              DataColumn(label: Text("Permanent Addr")),
              DataColumn(label: Text("Current Addr")),
              DataColumn(label: Text("Zipcode")),
             
              DataColumn(label: Text("Aadhar No")),
              DataColumn(label: Text("PAN No")),

              DataColumn(label: Text("Actions")),
            ],
            rows: _filteredInterns.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final id = doc.id;
              final isEditing = _editingInternId == id;

              final start = _startDateValues[id];
              final end = _endDateValues[id];

              return DataRow(cells: [
                DataCell(isEditing ? TextField(controller: _nameCtrls[id]) : Text(data['intern_name'] ?? '')),
                DataCell(isEditing ? TextField(controller: _emailCtrls[id]) : Text(data['intern_email'] ?? '')),
                DataCell(isEditing ? TextField(controller: _phoneCtrls[id]) : Text(data['intern_phone'] ?? '')),
                               // Alt Phone
DataCell(isEditing
    ? TextField(controller: _altPhoneCtrls[id])
    : Text(data['intern_alt_phone'] ?? '')),
                DataCell(isEditing ? TextField(controller: _collegeCtrls[id]) : Text(data['intern_college'] ?? '')),
                DataCell(isEditing ? TextField(controller: _courseCtrls[id]) : Text(data['intern_course'] ?? '')),
                DataCell(isEditing ? TextField(controller: _deptCtrls[id]) : Text(data['intern_dept'] ?? '')),
                DataCell(isEditing ? TextField(controller: _durationCtrls[id]) : Text(data['intern_duration'] ?? '')),
                DataCell(isEditing
                    ? DropdownButton<String>(
                        value: _genderValues[id],
                        items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                        onChanged: (val) => setState(() => _genderValues[id] = val ?? _genders.first),
                      )
                    : Text(data['intern_gender'] ?? '')),
                DataCell(isEditing ? TextField(controller: TextEditingController(text: _cityValues[id])) : Text(data['intern_city'] ?? '')),
                DataCell(isEditing ? TextField(controller: TextEditingController(text: _stateValues[id])) : Text(data['intern_state'] ?? '')),
                DataCell(isEditing
                    ? DropdownButton<String>(
                        value: _countryValues[id],
                        items: _countries.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) => setState(() => _countryValues[id] = val ?? _countries.first),
                      )
                    : Text(data['intern_country'] ?? '')),
                DataCell(isEditing
                    ? GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: start ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) setState(() => _startDateValues[id] = picked);
                        },
                        child: Text(start != null ? DateFormat('dd-MM-yyyy').format(start) : '--'),
                      )
                    : Text(start != null ? DateFormat('dd-MM-yyyy').format(start) : '--')),
                DataCell(isEditing
                    ? GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: end ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) setState(() => _endDateValues[id] = picked);
                        },
                        child: Text(end != null ? DateFormat('dd-MM-yyyy').format(end) : '--'),
                      )
                    : Text(end != null ? DateFormat('dd-MM-yyyy').format(end) : '--')),
                DataCell(isEditing ? TextField(controller: _permanentAddrCtrls[id]) : Text(data['intern_permanent_address'] ?? '')),
                DataCell(isEditing ? TextField(controller: _currentAddrCtrls[id]) : Text(data['intern_current_address'] ?? '')),
                DataCell(isEditing ? TextField(controller: _zipcodeCtrls[id]) : Text(data['intern_zipcode'] ?? '')),


// Aadhar No
DataCell(isEditing
    ? TextField(controller: _aadharCtrls[id])
    : Text(data['intern_aadhar_no'] ?? '')),

// PAN No
DataCell(isEditing
    ? TextField(controller: _panCtrls[id])
    : Text(data['intern_pan_no'] ?? '')),

                DataCell(Row(children: [
                  if (isEditing) ...[
                    IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () async => _saveRowEdits(id)),
                    IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: fetchInterns),
                  ] else ...[
                    IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => setState(() => _editingInternId = id)),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteIntern(id)),
                  ]
                ])),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: const LinearGradient(
            colors: [Color(0xFF34D0C6), Color(0xFF22A4E0), Color(0xFF1565C0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
          ],
        ),
        child: FloatingActionButton(
          elevation: 0,
          backgroundColor: Colors.transparent,
          tooltip: "Add New Intern",
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InternRegistration(
                  currentUserId: widget.currentUserId,
                  currentUserRole: widget.currentUserRole,
                ),
              ),
            ).then((_) => fetchInterns());
          },
          child: const Icon(Icons.add, color: Colors.white, size: 32),
        ),
      ),
      body: Column(
        children: [
          Container(
            height: kToolbarHeight + 10,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF34D0C6), Color(0xFF22A4E0), Color(0xFF1565C0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    BackButton(color: Colors.white),
                    Text("Intern List", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                    CircleAvatar(backgroundColor: Colors.white, backgroundImage: AssetImage('assets/logo.png')),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFEAF6FF), Colors.white],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _filterController,
                                onChanged: filterInterns,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.search),
                                  hintText: "Search by name, email, phone, college or department",
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF22A4E0),
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                              ),
                              icon: const Icon(Icons.refresh, color: Colors.white),
                              label: const Text("Refresh", style: TextStyle(color: Colors.white)),
                              onPressed: fetchInterns,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Expanded(child: _buildInternTable()),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
