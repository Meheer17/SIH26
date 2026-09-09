import 'package:flutter/material.dart';
import '../../core/auth/auth_service.dart';

class AdminRolesScreen extends StatefulWidget {
  const AdminRolesScreen({super.key});

  @override
  State<AdminRolesScreen> createState() => _AdminRolesScreenState();
}

class _AdminRolesScreenState extends State<AdminRolesScreen> {
  final _authService = AuthService();
  List<UserModel> _users = [];
  bool _isLoading = true;
  String? _errorMessage;

  final List<String> _availableRoles = [
    'PATIENT',
    'SOLDIER',
    'VICTIM',
    'CITIZEN',
    'PHYSICIAN',
    'WELFARE_OFFICER',
    'COUNSELOR',
    'COMMANDER',
    'DISTRICT_OFFICER',
    'STATE_ADMIN',
    'SYSTEM_ADMIN',
  ];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final users = await _authService.listAllUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _showEditRolesDialog(UserModel targetUser) {
    List<String> selectedRoles = List.from(targetUser.mappedRoles);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                'Assign Roles: ${targetUser.fullName}',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _availableRoles.length,
                  itemBuilder: (context, index) {
                    final role = _availableRoles[index];
                    final isChecked = selectedRoles.contains(role);
                    return CheckboxListTile(
                      activeColor: const Color(0xFF6366F1),
                      title: Text(
                        role,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                      value: isChecked,
                      onChanged: (bool? val) {
                        setDialogState(() {
                          if (val == true) {
                            selectedRoles.add(role);
                          } else {
                            selectedRoles.remove(role);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.of(context).pop();
                    try {
                      await _authService.mapUserRoles(
                        userId: targetUser.id,
                        roles: selectedRoles,
                      );
                      _fetchUsers();
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('Updated roles for ${targetUser.fullName}!')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('Failed: ${e.toString()}')),
                        );
                      }
                    }
                  },
                  child: const Text('Save Roles', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text('Admin Role Management', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.amberAccent))
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _fetchUsers, child: const Text('Retry')),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final u = _users[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  u.fullName,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                if (u.isAdmin) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.amber,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('ADMIN', style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.indigoAccent, size: 20),
                                  onPressed: () => _showEditRolesDialog(u),
                                ),
                              ],
                            ),
                            Text(u.emailOrPhone, style: const TextStyle(color: Colors.white60, fontSize: 12, fontFamily: 'monospace')),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 4,
                              children: u.mappedRoles.map((r) {
                                return Chip(
                                  label: Text(r, style: const TextStyle(fontSize: 10, color: Colors.white)),
                                  backgroundColor: const Color(0xFF0F172A),
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
