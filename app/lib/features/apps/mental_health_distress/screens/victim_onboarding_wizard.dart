import 'package:flutter/material.dart';
import '../services/nyaya_manas_service.dart';

class VictimOnboardingWizardScreen extends StatefulWidget {
  final Function(String newVictimId)? onOnboardingComplete;

  const VictimOnboardingWizardScreen({
    super.key,
    this.onOnboardingComplete,
  });

  @override
  State<VictimOnboardingWizardScreen> createState() => _VictimOnboardingWizardScreenState();
}

class _VictimOnboardingWizardScreenState extends State<VictimOnboardingWizardScreen> {
  final _service = NyayaManasService();
  int _currentStep = 1; // 1 to 5

  // Step 1: Language
  String _selectedLang = 'hi';
  final List<Map<String, String>> _languages = [
    {'code': 'hi', 'label': 'हिन्दी (Hindi / Awadhi)', 'native': 'हिन्दी'},
    {'code': 'ta', 'label': 'தமிழ் (Tamil)', 'native': 'தமிழ்'},
    {'code': 'te', 'label': 'తెలుగు (Telugu)', 'native': 'తెలుగు'},
    {'code': 'mr', 'label': 'मराठी (Marathi)', 'native': 'मराठी'},
    {'code': 'bn', 'label': 'বাংলা (Bengali)', 'native': 'বাংলা'},
    {'code': 'en', 'label': 'English (Indian)', 'native': 'English'},
  ];

  // Step 2: Identity & FIR
  final TextEditingController _nameController = TextEditingController(text: 'Kamla Devi');
  final TextEditingController _phoneController = TextEditingController(text: '+91 98765 43210');
  final TextEditingController _firController = TextEditingController(text: 'FIR-2026/0891-SCST');
  String _selectedDistrict = 'Varanasi';
  final String _selectedOffense = 'intimidation';

  // Step 3: Informed Consent (DPDP Act)
  bool _consentAudio = true;
  bool _consentOptOut = true;
  bool _consentEncrypted = true;

  // Step 4: Emergency Contacts
  final TextEditingController _contactNameController = TextEditingController(text: 'Sunil Kumar (Brother)');
  final TextEditingController _contactPhoneController = TextEditingController(text: '+91 98765 00112');
  final TextEditingController _contactRelController = TextEditingController(text: 'Sibling / Community Member');

  // Step 5: Stealth PIN
  final TextEditingController _pinController = TextEditingController(text: '1234');
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _firController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _contactRelController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    setState(() => _submitting = true);

    final payload = {
      'full_name': _nameController.text.trim(),
      'district': _selectedDistrict,
      'state': 'Uttar Pradesh',
      'tehsil': 'Varanasi Sadar',
      'police_station': 'Rohaniya Police Station',
      'fir_number': _firController.text.trim(),
      'fir_date': DateTime.now().toIso8601String().split('T')[0],
      'offense_category': _selectedOffense,
      'offense_title': 'Section 3(1)(r)(s) Criminal Intimidation & Witness Harassment',
      'preferred_language': _selectedLang,
      'preferred_channel': 'app',
      'statutory_relief_total': 825000.0,
      'statutory_relief_disbursed': 206250.0,
      'emergency_contact': {
        'name': _contactNameController.text.trim(),
        'phone': _contactPhoneController.text.trim(),
        'relationship': _contactRelController.text.trim(),
      },
      'stealth_pin': _pinController.text.trim(),
      'dpdp_consent_verified': _consentAudio && _consentOptOut && _consentEncrypted,
    };

    try {
      final res = await _service.registerVictim(payload);
      final newVictimId = res['victim_id'] ?? 'V-UP-VAR-NEW';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF059669),
            content: Text('✅ Onboarding Complete! Welcome to Nyaya-Manas ($newVictimId)'),
          ),
        );
        widget.onOnboardingComplete?.call(newVictimId);
        Navigator.pop(context, newVictimId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.redAccent, content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Nyaya-Manas: Victim Onboarding'),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        titleTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step Progress Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Step $_currentStep of 5: ${_getStepTitle(_currentStep)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF7C3AED)),
                      ),
                      Text('${(_currentStep * 20)}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _currentStep / 5.0,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildCurrentStepView(),
              ),
            ),

            // Bottom Navigation Controls
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  if (_currentStep > 1)
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF475569),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => setState(() => _currentStep--),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentStep > 1) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _submitting
                          ? null
                          : () {
                              if (_currentStep < 5) {
                                setState(() => _currentStep++);
                              } else {
                                _completeOnboarding();
                              }
                            },
                      child: _submitting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(
                              _currentStep == 5 ? '✓ Complete & Enter System' : 'Continue →',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 1:
        return 'Language & Dialect';
      case 2:
        return 'Case & Identity Verification';
      case 3:
        return 'DPDP Informed Consent';
      case 4:
        return 'Emergency Contacts';
      case 5:
        return 'Stealth PIN & Security';
      default:
        return '';
    }
  }

  Widget _buildCurrentStepView() {
    switch (_currentStep) {
      case 1:
        return _buildStep1Language();
      case 2:
        return _buildStep2Identity();
      case 3:
        return _buildStep3Consent();
      case 4:
        return _buildStep4Contacts();
      case 5:
        return _buildStep5StealthPin();
      default:
        return const SizedBox();
    }
  }

  Widget _buildStep1Language() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Your Primary Language', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
        const SizedBox(height: 6),
        const Text('All AI companions, IVRS calls, and trauma assessments will adapt to this tongue.', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
        const SizedBox(height: 18),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.4,
          ),
          itemCount: _languages.length,
          itemBuilder: (ctx, idx) {
            final lang = _languages[idx];
            final isSelected = _selectedLang == lang['code'];
            return InkWell(
              onTap: () => setState(() => _selectedLang = lang['code']!),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFF3E8FF) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFE2E8F0),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: 18,
                      color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        lang['label']!,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? const Color(0xFF6B21A8) : const Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStep2Identity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Atrocity Case Registration & Identity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
        const SizedBox(height: 6),
        const Text('Linked with e-Courts CCTNS & National Helpline Against Atrocities (14566).', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
        const SizedBox(height: 18),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Victim / Complainant Full Name',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          style: const TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: 'Mobile Phone # (for IVRS 14566 & OTP)',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          style: const TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _firController,
          decoration: InputDecoration(
            labelText: 'SC/ST PoA FIR Reference #',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          style: const TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _selectedDistrict,
          decoration: InputDecoration(
            labelText: 'District',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          items: const [
            DropdownMenuItem(value: 'Varanasi', child: Text('Varanasi, UP')),
            DropdownMenuItem(value: 'Lucknow', child: Text('Lucknow, UP')),
            DropdownMenuItem(value: 'Gorakhpur', child: Text('Gorakhpur, UP')),
            DropdownMenuItem(value: 'Agra', child: Text('Agra, UP')),
            DropdownMenuItem(value: 'Kanpur Nagar', child: Text('Kanpur Nagar, UP')),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _selectedDistrict = val);
          },
        ),
      ],
    );
  }

  Widget _buildStep3Consent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Informed Consent & DPDP Act 2023 Shield', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
        const SizedBox(height: 6),
        const Text('Your dignity and privacy are protected by law with zero raw audio storage.', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
        const SizedBox(height: 16),
        CheckboxListTile(
          value: _consentAudio,
          onChanged: (v) => setState(() => _consentAudio = v ?? true),
          activeColor: const Color(0xFF7C3AED),
          title: const Text('Ephemeral Voice Processing', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
          subtitle: const Text('Voice notes are processed in volatile RAM for acoustic tremor biomarkers and immediately discarded. No permanent audio recordings are kept.', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        ),
        const Divider(),
        CheckboxListTile(
          value: _consentOptOut,
          onChanged: (v) => setState(() => _consentOptOut = v ?? true),
          activeColor: const Color(0xFF7C3AED),
          title: const Text('Voluntary Participation & Opt-Out', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
          subtitle: const Text('You may pause automated check-ins or switch exclusively to toll-free IVRS at any time without affecting your statutory relief.', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        ),
        const Divider(),
        CheckboxListTile(
          value: _consentEncrypted,
          onChanged: (v) => setState(() => _consentEncrypted = v ?? true),
          activeColor: const Color(0xFF7C3AED),
          title: const Text('Encrypted Multi-Agency Coordination', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
          subtitle: const Text('Distress scores are shared only with your designated DMHP psychologist and District Witness Protection cell under Section 15A.', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        ),
      ],
    );
  }

  Widget _buildStep4Contacts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Emergency Contacts for Silent SOS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
        const SizedBox(height: 6),
        const Text('When SOS beacon is held for 3s, these contacts receive geofenced GPS alerts alongside police dispatch.', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
        const SizedBox(height: 18),
        TextField(
          controller: _contactNameController,
          decoration: InputDecoration(
            labelText: 'Primary Contact Full Name',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          style: const TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _contactPhoneController,
          decoration: InputDecoration(
            labelText: 'Contact Phone Number',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          style: const TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _contactRelController,
          decoration: InputDecoration(
            labelText: 'Relationship to Victim',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildStep5StealthPin() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Set Stealth Mode PIN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
        const SizedBox(height: 6),
        const Text('Disguises the entire app as a standard working calculator. Typing this 4-digit PIN returns you to Nyaya-Manas.', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
        const SizedBox(height: 20),
        Center(
          child: Container(
            width: 180,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF7C3AED), width: 1.5),
            ),
            child: TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              obscureText: true,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 8),
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                hintText: '••••',
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            children: const [
              Icon(Icons.shield_outlined, color: Color(0xFFD97706), size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Safety Tip: Use a PIN easy to remember under stress (e.g. 1234). You can trigger disguise at any time with one tap.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
