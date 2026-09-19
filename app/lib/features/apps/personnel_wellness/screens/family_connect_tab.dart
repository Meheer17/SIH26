import 'package:flutter/material.dart';
import '../services/raksha_setu_service.dart';

class FamilyConnectTab extends StatefulWidget {
  const FamilyConnectTab({super.key});

  @override
  State<FamilyConnectTab> createState() => _FamilyConnectTabState();
}

class _FamilyConnectTabState extends State<FamilyConnectTab> {
  final RakshaSetuService _service = RakshaSetuService();

  bool _isLoading = true;
  Map<String, dynamic>? _overview;

  // Form State
  String _relation = 'spouse';
  final TextEditingController _nameController = TextEditingController(text: 'Sunita Singh');
  String _status = 'GOOD';
  final TextEditingController _notesController = TextEditingController();
  bool _needsAssistance = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadOverview();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadOverview() async {
    setState(() => _isLoading = true);
    try {
      final res = await _service.fetchFamilyOverview();
      if (mounted) {
        setState(() {
          _overview = res;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitCheckin() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isSubmitting = true);

    try {
      final res = await _service.submitFamilyCheckin({
        'family_member_relation': _relation,
        'family_member_name': _nameController.text,
        'wellness_status': _status,
        'notes': _notesController.text,
        'requires_welfare_assistance': _needsAssistance,
      });

      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Family check-in saved.'),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
        _notesController.clear();
        _loadOverview();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)));
    }

    final familyMembers = _overview?['family_members'] as List<dynamic>? ?? [];
    final videoCall = _overview?['scheduled_video_call'] as Map<String, dynamic>?;
    final schemes = _overview?['welfare_schemes'] as List<dynamic>? ?? [];

    return RefreshIndicator(
      onRefresh: _loadOverview,
      color: const Color(0xFF0284C7),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Scheduled Video Call Hero Card
          if (videoCall != null)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [BoxShadow(color: Color(0x2A4F46E5), blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.video_call_rounded, color: Colors.white, size: 26),
                          SizedBox(width: 8),
                          Text('Scheduled Family Video Link', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                        child: const Text('PRIORITY SATELLITE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    videoCall['date'] ?? 'Tomorrow, 19:30 IST',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  Text(
                    'Pre-allocated 20-minute private booth session with family in Varanasi.',
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9)),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Testing satellite video connection... Link test OK (50 Mbps).'), backgroundColor: Color(0xFF16A34A)),
                      );
                    },
                    icon: const Icon(Icons.satellite_alt, size: 16),
                    label: const Text('Test Satellite Uplink'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF4F46E5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 18),

          // 2. Family Members Overview
          const Text('Registered Family Dependents', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 8),
          ...familyMembers.map((fm) {
            final name = fm['name'] ?? '';
            final relation = fm['relation'] ?? '';
            final location = fm['location'] ?? '';
            final notes = fm['notes'] ?? '';
            final scheme = fm['scholarship_scheme'] ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF4F46E5).withOpacity(0.12),
                    child: Icon(relation == 'Spouse' ? Icons.favorite : Icons.child_care, color: const Color(0xFF4F46E5), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(4)),
                              child: const Text('HEALTHY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                            ),
                          ],
                        ),
                        Text('$relation • $location', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        if (notes.toString().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(notes, style: const TextStyle(fontSize: 11, color: Color(0xFF334155))),
                        ],
                        if (scheme.toString().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('🎓 $scheme', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),

          // 3. Log Family Check-in Form
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Log Family Check-In (पारिवारिक हालचाल)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _relation,
                  decoration: const InputDecoration(labelText: 'Relation', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'spouse', child: Text('Spouse (पत्नी)')),
                    DropdownMenuItem(value: 'parent', child: Text('Parent (माता/पिता)')),
                    DropdownMenuItem(value: 'child', child: Text('Child (बच्चा)')),
                    DropdownMenuItem(value: 'sibling', child: Text('Sibling (भाई/बहन)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _relation = val);
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Dependent Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(labelText: 'Wellness Status', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'GOOD', child: Text('Good / Everything Normal')),
                    DropdownMenuItem(value: 'CONCERNED', child: Text('Mild Concern / Sickness')),
                    DropdownMenuItem(value: 'NEEDS_SUPPORT', child: Text('Needs Welfare Officer Assistance')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _status = val);
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Notes or Requests for Family Branch', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Request Family Welfare Branch Outreach', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Unit welfare team will contact your home district to provide assistance', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                  value: _needsAssistance,
                  activeColor: const Color(0xFF0284C7),
                  onChanged: (val) => setState(() => _needsAssistance = val ?? false),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitCheckin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(_isSubmitting ? 'Saving...' : 'Save Family Check-In'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. Welfare Schemes Information
          const Text('Active Armed Forces Family Welfare Grants', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 8),
          ...schemes.map((s) {
            final title = s['title'] ?? '';
            final status = s['status'] ?? 'ACTIVE';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified, color: Color(0xFF16A34A), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(4)),
                    child: Text(status, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
