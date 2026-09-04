import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CommunityImmunityNetworkScreen extends StatefulWidget {
  const CommunityImmunityNetworkScreen({super.key});

  @override
  State<CommunityImmunityNetworkScreen> createState() => _CommunityImmunityNetworkScreenState();
}

class _CommunityImmunityNetworkScreenState extends State<CommunityImmunityNetworkScreen> {
  bool _loading = false;
  Map<String, dynamic>? _meshData;

  final List<Map<String, dynamic>> _discoveredNodes = [
    {"id": "NODE-88A1", "rssi": -42, "battery": 92, "symptoms": ["Fever", "Heat Exhaustion"]},
    {"id": "NODE-71F4", "rssi": -65, "battery": 78, "symptoms": ["Dry Cough"]},
    {"id": "NODE-33C9", "rssi": -58, "battery": 84, "symptoms": ["Fever", "Chills"]},
    {"id": "NODE-90E2", "rssi": -71, "battery": 60, "symptoms": []},
  ];

  Future<void> _fetchMeshSync() async {
    setState(() => _loading = true);
    try {
      final response = await http.get(Uri.parse('http://localhost:8000/api/v1/cin/outbreaks'));
      if (response.statusCode == 200) {
        setState(() {
          _meshData = jsonDecode(response.body);
        });
      }
    } catch (e) {
      debugPrint('CIN sync error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchMeshSync();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'OFFLINE BLE MESH',
                    style: TextStyle(color: Color(0xFF166534), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Text(
              'Community Immunity Network',
              style: TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: _loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh, color: Color(0xFF0F172A)),
            onPressed: _fetchMeshSync,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Outbreak Banner
            if (_meshData != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _meshData!['outbreak_detected'] == true ? const Color(0xFFFEF3C7) : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _meshData!['outbreak_detected'] == true ? const Color(0xFFFCD34D) : const Color(0xFFA7F3D0),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _meshData!['outbreak_detected'] == true ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                      color: _meshData!['outbreak_detected'] == true ? const Color(0xFF92400E) : const Color(0xFF065F46),
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mesh Alert: ${_meshData!['risk_level']} RISK',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _meshData!['alert_message'] ?? '',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Stat Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('Active Mesh Nodes', '${_meshData?['total_mesh_nodes'] ?? 4}', Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Fever Spikes', '${_meshData?['fever_count'] ?? 3}', const Color(0xFFE11D48)),
                ),

              ],
            ),
            const SizedBox(height: 20),

            const Text(
              'Discovered Nearby BLE Nodes',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _discoveredNodes.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final node = _discoveredNodes[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bluetooth, color: Color(0xFF2563EB)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              node['id'],
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              'RSSI: ${node['rssi']} dBm | Batt: ${node['battery']}%',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (node['symptoms'] as List).isNotEmpty ? const Color(0xFFFFE4E6) : const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          (node['symptoms'] as List).isNotEmpty ? node['symptoms'].join(', ') : 'Asymptomatic',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: (node['symptoms'] as List).isNotEmpty ? const Color(0xFF9F1239) : const Color(0xFF166534),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
