import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class GroundbreakingSuiteScreen extends StatefulWidget {
  const GroundbreakingSuiteScreen({super.key});

  @override
  State<GroundbreakingSuiteScreen> createState() => _GroundbreakingSuiteScreenState();
}

class _GroundbreakingSuiteScreenState extends State<GroundbreakingSuiteScreen> {
  int _selectedTab = 0;
  bool _loading = false;
  Map<String, dynamic>? _digitalTwinData;
  Map<String, dynamic>? _karmaData;
  Map<String, dynamic>? _federatedStatus;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _loading = true);
    try {
      final dtRes = await http.get(Uri.parse('http://localhost:8000/api/v1/apps/digital-twin'));
      final kmRes = await http.get(Uri.parse('http://localhost:8000/api/v1/apps/karma'));
      final fedRes = await http.get(Uri.parse('http://localhost:8000/api/v1/ai/federated/status'));

      setState(() {
        if (dtRes.statusCode == 200) _digitalTwinData = jsonDecode(dtRes.body);
        if (kmRes.statusCode == 200) _karmaData = jsonDecode(kmRes.body);
        if (fedRes.statusCode == 200) _federatedStatus = jsonDecode(fedRes.body);
      });
    } catch (e) {
      debugPrint('Error loading groundbreaking data: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Groundbreaking AI Features',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'SIH 2026 Ecosystem Innovation',
              style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tab Selector
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildTabChip(0, '3D Digital Twin'),
                        _buildTabChip(1, 'Health Karma'),
                        _buildTabChip(2, 'Federated AI'),
                        _buildTabChip(3, 'ASHA Copilot'),
                        _buildTabChip(4, 'Evidence Chain'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_selectedTab == 0) _buildDigitalTwinView(),
                  if (_selectedTab == 1) _buildHealthKarmaView(),
                  if (_selectedTab == 2) _buildFederatedView(),
                  if (_selectedTab == 3) _buildAshaCopilotView(),
                  if (_selectedTab == 4) _buildEvidenceChainView(),
                ],
              ),
            ),
    );
  }

  Widget _buildTabChip(int index, String label) {
    final isSelected = _selectedTab == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedTab = index),
        selectedColor: const Color(0xFF0284C7),
        backgroundColor: const Color(0xFF1E293B),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF94A3B8),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildDigitalTwinView() {
    if (_digitalTwinData == null) return const Text('No digital twin data', style: TextStyle(color: Colors.white70));
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        children: [
          const Icon(Icons.person_pin_outlined, size: 64, color: Color(0xFF38BDF8)),
          const SizedBox(height: 12),
          Text(
            'Overall Health Score: ${_digitalTwinData!['overall_health_score']}',
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            _digitalTwinData!['health_score_trajectory'] ?? '',
            style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const Divider(color: Color(0xFF1E293B), height: 32),
          _buildOrganRow('Cardiovascular', _digitalTwinData!['organ_health']['cardiovascular']['score'], const Color(0xFFF43F5E)),
          _buildOrganRow('Pulmonary', _digitalTwinData!['organ_health']['pulmonary']['score'], Colors.indigoAccent),
          _buildOrganRow('Metabolic', _digitalTwinData!['organ_health']['metabolic']['score'], Colors.amberAccent),
          _buildOrganRow('Mental / Stress', _digitalTwinData!['organ_health']['neurological_mental']['score'], Colors.purpleAccent),
        ],
      ),
    );
  }

  Widget _buildOrganRow(String name, int score, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text('$score / 100', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthKarmaView() {
    if (_karmaData == null) return const Text('No karma data', style: TextStyle(color: Colors.white70));
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stars_rounded, color: Colors.amberAccent, size: 36),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_karmaData!['karma_points_balance']} Points',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(_karmaData!['tier'] ?? '', style: const TextStyle(color: Colors.amberAccent, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Redeemable Healthcare Vouchers', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...((_karmaData!['redeemable_rewards'] as List).map((r) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.card_giftcard, color: Color(0xFF38BDF8)),
                title: Text(r['title'], style: const TextStyle(color: Colors.white, fontSize: 13)),
                subtitle: Text(r['partner'], style: const TextStyle(color: Colors.white54, fontSize: 11)),
                trailing: Text('${r['cost_points']} pts', style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
              ))),
        ],
      ),
    );
  }

  Widget _buildFederatedView() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: Color(0xFF4ADE80)),
              SizedBox(width: 8),
              Text('Federated Learning Active', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'On-Device FedAvg Engine ensures raw audio & health data never leave this device. Encrypted gradients are uploaded to update global disease prediction models.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildAshaCopilotView() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ASHA Field Triage Assistant', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(height: 8),
          Text('MoHFW Ante-Natal & High-Risk Maternal Triage Protocol.', style: TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildEvidenceChainView() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BSA 2023 Sec 63 Legal Evidence Chain', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(height: 8),
          Text('Tamper-evident SHA-256 Merkle tree for victim protection.', style: TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}
