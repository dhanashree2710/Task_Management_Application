import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:task_management_application/modules/Admin/presentation/widgets/admin_register.dart';

class UserListScreen extends StatefulWidget {
  final String currentUserId;
  final String currentUserRole;

  const UserListScreen({
    super.key,
    required this.currentUserId,
    required this.currentUserRole,
  });

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _horizontalScroll = ScrollController();
  final ScrollController _verticalScroll = ScrollController();

  List<DocumentSnapshot> _users = [];
  List<DocumentSnapshot> _filteredUsers = [];
  bool _loading = true;
  String? _editingId;

  // Controllers
  final Map<String, TextEditingController> _nameCtrls = {};
  final Map<String, TextEditingController> _emailCtrls = {};
  final Map<String, TextEditingController> _passwordCtrls = {};
  final Map<String, String> _roleValues = {};

  final List<String> _roles = ['admin', 'intern', 'employee'];

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }
  @override
void dispose() {
  _verticalScroll.dispose();
  _horizontalScroll.dispose();
  super.dispose();
}

  Future<void> fetchUsers() async {
    setState(() => _loading = true);
    final snapshot = await FirebaseFirestore.instance.collection('users').get();

    setState(() {
      _users = snapshot.docs;
      _filteredUsers = _users;
      _loading = false;
    });

    for (var doc in _users) {
      final id = doc.id;
      final data = doc.data() as Map<String, dynamic>;

      _nameCtrls.putIfAbsent(
        id,
        () => TextEditingController(text: data['user_name'] ?? ''),
      );
      _emailCtrls.putIfAbsent(
        id,
        () => TextEditingController(text: data['user_email'] ?? ''),
      );
      _passwordCtrls.putIfAbsent(
        id,
        () => TextEditingController(text: data['user_password'] ?? ''),
      );

      _roleValues.putIfAbsent(id, () => data['role'] ?? _roles.first);
    }
  }

  void filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = _users;
      } else {
        _filteredUsers =
            _users.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return (data['user_name'] ?? '')
                      .toString()
                      .toLowerCase()
                      .contains(query.toLowerCase()) ||
                  (data['user_email'] ?? '').toString().toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  (data['role'] ?? '').toString().toLowerCase().contains(
                    query.toLowerCase(),
                  );
            }).toList();
      }
    });
  }

  Future<void> _updateUser(String id) async {
    await FirebaseFirestore.instance.collection('users').doc(id).update({
      'user_name': _nameCtrls[id]?.text ?? '',
      'user_email': _emailCtrls[id]?.text ?? '',
      'user_password': _passwordCtrls[id]?.text ?? '',
      'role': _roleValues[id],
    });

    await fetchUsers();
    setState(() => _editingId = null);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("User updated")));
  }

  Future<void> _deleteUser(String id) async {
    await FirebaseFirestore.instance.collection('users').doc(id).delete();
    fetchUsers();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("User deleted")));
  }

  Widget _buildTable() {
    return Scrollbar(
    controller: _verticalScroll, // ✅ REQUIRED
    thumbVisibility: true,
    child: SingleChildScrollView(
      controller: _verticalScroll, // ✅ SAME controller
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        controller: _horizontalScroll, // ✅ horizontal controller
        scrollDirection: Axis.horizontal,
        child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFF076AB1)),
            headingTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            border: TableBorder.all(color: Colors.grey.shade300),
            columns: const [
              DataColumn(label: Text("Name")),
              DataColumn(label: Text("Email")),
              DataColumn(label: Text("Password")),
              DataColumn(label: Text("Role")),
              DataColumn(label: Text("Created At")),
              DataColumn(label: Text("Actions")),
            ],
            rows:
                _filteredUsers.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final id = doc.id;
                  final isEditing = _editingId == id;

                  final createdAt =
                      data['created_at'] is Timestamp
                          ? DateFormat(
                            'dd-MM-yyyy',
                          ).format((data['created_at'] as Timestamp).toDate())
                          : '--';

                  return DataRow(
                    cells: [
                      DataCell(
                        isEditing
                            ? TextField(controller: _nameCtrls[id])
                            : Text(data['user_name'] ?? ''),
                      ),

                      DataCell(
                        isEditing
                            ? TextField(controller: _emailCtrls[id])
                            : Text(data['user_email'] ?? ''),
                      ),

                      DataCell(
                        isEditing
                            ? TextField(controller: _passwordCtrls[id])
                            : Text(data['user_password'] ?? ''),
                      ),

                      DataCell(
                        isEditing
                            ? DropdownButton<String>(
                              value: _roleValues[id],
                              items:
                                  _roles
                                      .map(
                                        (r) => DropdownMenuItem(
                                          value: r,
                                          child: Text(r),
                                        ),
                                      )
                                      .toList(),
                              onChanged:
                                  (val) =>
                                      setState(() => _roleValues[id] = val!),
                            )
                            : Text(data['role'] ?? ''),
                      ),

                      DataCell(Text(createdAt)),

                      DataCell(
                        Row(
                          children:
                              isEditing
                                  ? [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.check,
                                        color: Colors.green,
                                      ),
                                      onPressed: () => _updateUser(id),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.red,
                                      ),
                                      onPressed: fetchUsers,
                                    ),
                                  ]
                                  : [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      onPressed:
                                          () => setState(() => _editingId = id),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _deleteUser(id),
                                    ),
                                  ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchCtrl,
      onChanged: filterUsers,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: "Search users...",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildAddUserButton() {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => AdminRegistration(
                    currentUserId: widget.currentUserId,
                    currentUserRole: widget.currentUserRole,
                  ),
            ),
          );
        },
        icon: const Icon(Icons.person_add),
        label: const Text("Add User"),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
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
              colors: [Color(0xFF34D0C6), Color(0xFF22A4E0), Color(0xFF1565C0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 4,
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;

                    return Column(
                      children: [
                        isMobile
                            ? Column(
                              children: [
                                _buildSearchField(),
                                const SizedBox(height: 12),
                                _buildAddUserButton(),
                              ],
                            )
                            : Row(
                              children: [
                                Expanded(child: _buildSearchField()),
                                const SizedBox(width: 12),
                                _buildAddUserButton(),
                              ],
                            ),
                        const SizedBox(height: 16),
                        Expanded(child: _buildTable()),
                      ],
                    );
                  },
                ),
              ),
    );
  }
}
