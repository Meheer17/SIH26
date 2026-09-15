import 'package:flutter/material.dart';
import '../../../../core/auth/auth_service.dart';

class MentalHealthAuthScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const MentalHealthAuthScreen({
    super.key,
    required this.onLoginSuccess,
  });

  @override
  State<MentalHealthAuthScreen> createState() => _MentalHealthAuthScreenState();
}

class _MentalHealthAuthScreenState extends State<MentalHealthAuthScreen> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'victim_scst@district.gov.in');
  final _passwordController = TextEditingController(text: 'demo123456');
  final _nameController = TextEditingController(text: 'Rajesh Kumar');

  bool _isLogin = true;
  bool _isLoading = false;
  String _selectedRole = 'VICTIM_COMPLAINANT';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await _authService.login(
          emailOrPhone: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        await _authService.register(
          fullName: _nameController.text.trim(),
          emailOrPhone: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          primaryRole: _selectedRole,
          appContext: 'mental_health_nhaa',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF059669),
            content: Text('✅ Welcome to NHAA 14566 Distress System as ${_authService.currentUser?.primaryRole ?? _selectedRole}'),
          ),
        );
        widget.onLoginSuccess();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Auth error: ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _quickSelectRole(String role, String email) {
    setState(() {
      _selectedRole = role;
      _emailController.text = email;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('NHAA 14566 Authentication'),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        titleTextStyle: const TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0F0F172A),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor: const Color(0xFFEEF2FF),
                        child: const Icon(Icons.psychology, size: 36, color: Color(0xFF4F46E5)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        _isLogin ? 'Sign In to Distress Monitoring' : 'Register New Account',
                        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Center(
                      child: Text(
                        'National Helpline Against Atrocities (NHAA - 14566)',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Role Selection Chips
                    const Text('Select Your System Role:',
                        style: TextStyle(color: Color(0xFF475569), fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _roleChip('VICTIM_COMPLAINANT', 'Victim/Complainant', 'victim_scst@district.gov.in'),
                        _roleChip('DISTRICT_COUNSELOR', 'District Counselor', 'legal_officer@district.gov.in'),
                        _roleChip('DISTRICT_MAGISTRATE', 'District Magistrate/SP', 'dm_varanasi@up.gov.in'),
                        _roleChip('STATE_NODAL_OFFICER', 'State Nodal Officer', 'nodal_state@up.gov.in'),
                      ],
                    ),
                    const SizedBox(height: 20),

                    if (!_isLogin) ...[
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: Color(0xFF0F172A)),
                        decoration: _inputDecoration('Full Name', Icons.person),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                    ],

                    TextFormField(
                      controller: _emailController,
                      style: const TextStyle(color: Color(0xFF0F172A)),
                      decoration: _inputDecoration('Email / Official ID', Icons.email),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Color(0xFF0F172A)),
                      decoration: _inputDecoration('Password', Icons.lock),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(_isLogin ? 'SIGN IN' : 'REGISTER ACCOUNT',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Center(
                      child: TextButton(
                        onPressed: () => setState(() => _isLogin = !_isLogin),
                        child: Text(
                          _isLogin ? "Don't have an account? Register" : 'Already have an account? Sign In',
                          style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleChip(String roleKey, String label, String demoEmail) {
    final isSelected = _selectedRole == roleKey;
    return ChoiceChip(
      selected: isSelected,
      label: Text(label, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : const Color(0xFF334155))),
      selectedColor: const Color(0xFF4F46E5),
      backgroundColor: const Color(0xFFF1F5F9),
      side: BorderSide(color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0)),
      onSelected: (_) => _quickSelectRole(roleKey, demoEmail),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
      prefixIcon: Icon(icon, color: const Color(0xFF4F46E5), size: 20),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
    );
  }
}
