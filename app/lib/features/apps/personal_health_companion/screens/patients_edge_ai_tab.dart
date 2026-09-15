import 'package:flutter/material.dart';

class PatientsEdgeAiTab extends StatefulWidget {
  const PatientsEdgeAiTab({super.key});

  @override
  State<PatientsEdgeAiTab> createState() => _PatientsEdgeAiTabState();
}

class _PatientsEdgeAiTabState extends State<PatientsEdgeAiTab> {
  bool _offlineModeActive = true;
  bool _zeroCloudTransmission = true;

  final List<Map<String, dynamic>> _patientProfiles = [
    {
      'name': 'Ramesh Kumar (Self)',
      'relation': 'Self (Outdoor Construction Worker)',
      'age': 48,
      'riskLevel': 'MODERATE HEAT RISK',
      'color': const Color(0xFFD97706),
      'device': 'Fitness Band (BLE Sync Active)',
      'lastVitals': 'HR 72 bpm • SpO2 98% • Temp 37.1°C',
    },
    {
      'name': 'Savitri Devi (Mother)',
      'relation': 'Elderly Parent (Hypertension)',
      'age': 72,
      'riskLevel': 'HIGH HEAT & DEHYDRATION RISK',
      'color': const Color(0xFFE11D48),
      'device': 'Smartwatch (Continuous Monitor)',
      'lastVitals': 'HR 84 bpm • SpO2 96% • Temp 37.5°C',
    },
    {
      'name': 'Aarav Kumar (Son)',
      'relation': 'Child (Asthma History)',
      'age': 9,
      'riskLevel': 'AQI RESPIRATORY ALERT',
      'color': const Color(0xFF7C3AED),
      'device': 'Smart Sensor Band',
      'lastVitals': 'HR 92 bpm • SpO2 97%',
    },
  ];

  final List<Map<String, String>> _pairedDevices = [
    {'name': 'Boat Storm Smartwatch', 'type': 'BLE Wearable', 'status': 'CONNECTED'},
    {'name': 'On-Device Thermal Sensor', 'type': 'Skin Temp Probe', 'status': 'ACTIVE'},
    {'name': 'Smartphone Accelerometer', 'type': 'Fall & Motion Sensor', 'status': 'ACTIVE'},
  ];

  void _showAddPatientDialog() {
    final nameCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    String relationVal = 'Family Member / Dependent';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.person_add, color: Color(0xFF059669)),
              SizedBox(width: 8),
              Text('Add Patient / Family Member', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Patient Full Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: ageCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Age', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: relationVal,
                decoration: const InputDecoration(labelText: 'Category / Risk Group', border: OutlineInputBorder()),
                items: ['Elderly Parent', 'Outdoor Worker', 'Child / Student', 'Chronic Disease Patient', 'Family Member / Dependent']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 12))))
                    .toList(),
                onChanged: (v) => relationVal = v!,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('CANCEL'),
              onPressed: () => Navigator.pop(ctx),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
              child: const Text('ADD PATIENT'),
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  setState(() {
                    _patientProfiles.add({
                      'name': nameCtrl.text,
                      'relation': relationVal,
                      'age': int.tryParse(ageCtrl.text) ?? 30,
                      'riskLevel': 'STABLE / MONITORED',
                      'color': const Color(0xFF059669),
                      'device': 'BLE Wearable (Pending Pair)',
                      'lastVitals': 'HR 76 bpm • SpO2 98%',
                    });
                  });
                }
                Navigator.pop(ctx);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Patient Management & Edge AI Privacy Engine
          _buildPatientsHeader(),
          const SizedBox(height: 20),

          // Multi-Patient Management ("Add Patient" Portal)
          _buildPatientManagementCard(),
          const SizedBox(height: 20),

          // Paired Wearables & Device Manager
          _buildPairedDevicesCard(),
          const SizedBox(height: 20),

          // 100% Privacy-Preserving Edge AI Engine Card
          _buildEdgeAiPrivacyCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPatientsHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.people_outline, color: Color(0xFF16A34A), size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Multi-Patient & Wearable Hub',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('ZERO-CLOUD TRANSMISSION', style: TextStyle(color: Color(0xFF16A34A), fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Manage family members, elderly parents, and outdoor workers under 100% local Edge AI privacy.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientManagementCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.person_add_alt, color: Color(0xFF059669)),
                  SizedBox(width: 8),
                  Text(
                    'Family & Vulnerable Patient Profiles',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('ADD PATIENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                onPressed: _showAddPatientDialog,
              ),
            ],
          ),
          const SizedBox(height: 12),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _patientProfiles.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, idx) {
              final p = _patientProfiles[idx];
              final color = p['color'] as Color;

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: color.withValues(alpha: 0.15),
                      child: Icon(Icons.person, color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(p['name'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                child: Text(p['riskLevel'] as String, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          Text('${p["relation"]} (Age: ${p["age"]}) • ${p["device"]}', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                          Text('Vitals: ${p["lastVitals"]}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPairedDevicesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.watch, color: Color(0xFF0284C7)),
              SizedBox(width: 8),
              Text(
                'Paired Health Wearables & Sensors',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Column(
            children: _pairedDevices.map((d) {
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${d["name"]} (${d["type"]})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    Text(d['status']!, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEdgeAiPrivacyCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.security, color: Color(0xFF7C3AED)),
              SizedBox(width: 8),
              Text(
                'Privacy-Preserving Edge AI & Offline Operations',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          SwitchListTile(
            title: const Text('Strict Offline Mode (Zero Internet Transmission)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            subtitle: const Text('Ensures health analytics continue during network outages or extreme disaster events.', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
            value: _offlineModeActive,
            activeTrackColor: const Color(0xFF7C3AED),
            onChanged: (v) => setState(() => _offlineModeActive = v),
          ),
        ],
      ),
    );
  }
}
