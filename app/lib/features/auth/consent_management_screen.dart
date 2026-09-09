import 'package:flutter/material.dart';
import '../../core/auth/auth_service.dart';

class ConsentManagementScreen extends StatefulWidget {
  const ConsentManagementScreen({super.key});

  @override
  State<ConsentManagementScreen> createState() => _ConsentManagementScreenState();
}

class _ConsentManagementScreenState extends State<ConsentManagementScreen> {
  final _authService = AuthService();
  List<ConsentModel> _consents = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchConsents();
  }

  Future<void> _fetchConsents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final consents = await _authService.listMyConsents();
      setState(() {
        _consents = consents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _handleRevoke(String consentId) async {
    try {
      await _authService.revokeConsent(consentId);
      _fetchConsents();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to revoke: ${e.toString()}')),
        );
      }
    }
  }

  void _showGrantConsentDialog() {
    final granteeController = TextEditingController();
    final purposeController = TextEditingController(text: 'Clinical OPD History & Vitals Review');
    int durationDays = 30;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Grant New Data Consent', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: granteeController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Specialist Name / ID',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: purposeController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Authorized Purpose',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
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
                final grantee = granteeController.text.trim();
                final purpose = purposeController.text.trim();
                if (grantee.isEmpty || purpose.isEmpty) return;

                final messenger = ScaffoldMessenger.of(context);
                Navigator.of(context).pop();
                try {
                  await _authService.grantConsent(
                    granteeName: grantee,
                    purpose: purpose,
                    scopes: ['vitals:read', 'medical_history:read'],
                    durationDays: durationDays,
                  );
                  _fetchConsents();
                } catch (e) {
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Failed: ${e.toString()}')),
                    );
                  }
                }
              },
              child: const Text('Confirm Grant', style: TextStyle(color: Colors.white)),
            ),
          ],
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
        title: const Text('Consent Engine (DPDP Act)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_moderator, color: Colors.indigoAccent),
            onPressed: _showGrantConsentDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.indigoAccent))
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _fetchConsents, child: const Text('Retry')),
                      ],
                    ),
                  )
                : _consents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock_outline, size: 48, color: Colors.white38),
                            const SizedBox(height: 12),
                            const Text(
                              'No Active Data Grants',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Your health data is completely private.',

                          style: TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _showGrantConsentDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Grant Consent'),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _consents.length,
                    itemBuilder: (context, index) {
                      final c = _consents[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: c.isRevoked ? Colors.red.withValues(alpha: 0.3) : Colors.indigoAccent.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  c.granteeName,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: c.isRevoked ? Colors.red.withValues(alpha: 0.2) : Colors.green.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    c.isRevoked ? 'REVOKED' : 'ACTIVE',
                                    style: TextStyle(
                                      color: c.isRevoked ? Colors.redAccent : const Color(0xFF10B981),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(c.purpose, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 8),
                            if (!c.isRevoked) ...[
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () => _handleRevoke(c.id),
                                  icon: const Icon(Icons.block, size: 16, color: Colors.redAccent),
                                  label: const Text('Revoke Consent', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
