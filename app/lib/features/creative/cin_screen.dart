import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/api/api_endpoints.dart';
import '../../core/ml/mobile_ml_engine.dart';

class CommunityImmunityNetworkScreen extends StatefulWidget {
  const CommunityImmunityNetworkScreen({super.key});

  @override
  State<CommunityImmunityNetworkScreen> createState() => _CommunityImmunityNetworkScreenState();
}

class _CommunityImmunityNetworkScreenState extends State<CommunityImmunityNetworkScreen> {
  bool _loading = false;
  Map<String, dynamic>? _meshData;

  final TextEditingController _symptomController = TextEditingController(text: 'fever, dry cough');
  final TextEditingController _tempController = TextEditingController(text: '38.2');

  final List<Map<String, dynamic>> _discoveredNodes = [
    {"id": "8088e6406e2a1132", "ttl": 7, "battery": 92, "symptoms": ["Fever", "Heat Exhaustion"], "hmac": "3f8b9a2c1d0e", "temp": 38.5},
    {"id": "71f49b1a09c488e1", "ttl": 6, "battery": 78, "symptoms": ["Dry Cough"], "hmac": "7a1e4c9f0b2d", "temp": 37.2},
    {"id": "33c910e5b721aa45", "ttl": 5, "battery": 84, "symptoms": ["Fever", "Chills"], "hmac": "9c2d1b4a8e0f", "temp": 38.9},
    {"id": "90e28f73120b66c9", "ttl": 7, "battery": 60, "symptoms": ["Asymptomatic"], "hmac": "5e0f9b3a1c4d", "temp": 36.8},
  ];

  Future<void> _fetchMeshSync() async {
    setState(() => _loading = true);
    try {
      final response = await http.get(Uri.parse(ApiEndpoints.endpoint('cin/outbreaks')));
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

  Future<void> _broadcastBitMeshPacket() async {
    setState(() => _loading = true);
    try {
      final symptomsList = _symptomController.text.split(',').map((s) => s.trim()).toList();
      final body = [
        {
          "device_mac_or_uuid": "device-mobile-${DateTime.now().millisecondsSinceEpoch % 10000}",
          "symptoms": symptomsList,
          "fever_celsius": double.tryParse(_tempController.text) ?? 38.0,
          "ambient_temp_celsius": 33.5,
          "ttl": 7
        },
        ..._discoveredNodes.map((n) => {
          "device_mac_or_uuid": n["id"],
          "symptoms": n["symptoms"],
          "fever_celsius": n["temp"] ?? 37.0,
          "ambient_temp_celsius": 32.5,
          "ttl": n["ttl"]
        }),
      ];

      final response = await http.post(
        Uri.parse(ApiEndpoints.endpoint('cin/sync')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        setState(() {
          _meshData = jsonDecode(response.body);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('BitMesh Swarm Packet Broadcasted & R0 Recalculated!')),
          );
        }
      }
    } catch (e) {
      // Local ML R0 calculation fallback
      final temp = double.tryParse(_tempController.text) ?? 38.0;
      final symptomsList = _symptomController.text.split(',').map((s) => s.trim()).toList();
      final localRisk = MobileMlEngine.evaluateEpidemicClusterRisk(
        clusterSize: _discoveredNodes.length + 1,
        growthRate: 1.8,
        feverRatio: temp >= 37.8 ? 0.6 : 0.2,
        respiratoryRatio: symptomsList.any((s) => s.contains('cough')) ? 0.5 : 0.1,
        populationDensity: 12000,
        pastOutbreakHistory: true,
      );

      setState(() {
        _meshData = {
          "risk_level": localRisk['risk_tier'],
          "estimated_r0": (1.1 + (localRisk['risk_score'] as double) / 40.0).toStringAsFixed(2),
          "alert_message": "BitMesh Swarm: Outbreak risk evaluated via local Mobile ML engine.",
          "total_mesh_nodes": _discoveredNodes.length + 1,
          "outbreak_detected": localRisk['containment_protocol_active'],
        };
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offline Mode: BitMesh Swarm R0 evaluated locally.')),
        );
      }
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
  void dispose() {
    _symptomController.dispose();
    _tempController.dispose();
    super.dispose();
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
                    'BitChat-BitMesh P2P v2.6',
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'BitMesh: ${_meshData!['risk_level']} RISK',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: _meshData!['outbreak_detected'] == true ? const Color(0xFF78350F) : const Color(0xFF065F46),
                                ),
                              ),
                              Text(
                                'R0 = ${_meshData!['estimated_r0'] ?? "1.20"}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: _meshData!['outbreak_detected'] == true ? const Color(0xFF92400E) : const Color(0xFF047857),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _meshData!['alert_message'] ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: _meshData!['outbreak_detected'] == true ? const Color(0xFF78350F) : const Color(0xFF065F46),
                            ),
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
                  child: _buildStatCard('BitMesh Peers', '${_meshData?['total_mesh_nodes'] ?? 4}', Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Swarm R0 Rate', '${_meshData?['estimated_r0'] ?? 1.25}', const Color(0xFFE11D48)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Broadcast BitMesh Packet UI
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Broadcast BitMesh Epidemic Token',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _symptomController,
                    decoration: const InputDecoration(
                      labelText: 'Symptoms (comma separated)',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _tempController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Body Temp (°C)',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _loading ? null : _broadcastBitMeshPacket,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 42),
                    ),
                    icon: const Icon(Icons.cell_tower, size: 18),
                    label: const Text('Broadcast P2P BitMesh Packet'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'BitChat Store-and-Forward Gossip Peers',
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
                      const Icon(Icons.bluetooth_searching, color: Color(0xFF2563EB)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              node['id'],
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'monospace'),
                            ),
                            Text(
                              'TTL: ${node['ttl']}/7 | HMAC: ${node['hmac']}',
                              style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                      ),
                      Builder(builder: (_) {
                        final symptomsList = (node['symptoms'] is List) ? (node['symptoms'] as List) : [];
                        final hasSymptoms = symptomsList.isNotEmpty;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: hasSymptoms ? const Color(0xFFFFE4E6) : const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            symptomsList.join(', '),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: hasSymptoms ? const Color(0xFF9F1239) : const Color(0xFF166534),
                            ),
                          ),
                        );
                      }),
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

