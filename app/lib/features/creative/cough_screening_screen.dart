import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CoughScreeningScreen extends StatefulWidget {
  const CoughScreeningScreen({super.key});

  @override
  State<CoughScreeningScreen> createState() => _CoughScreeningScreenState();
}

class _CoughScreeningScreenState extends State<CoughScreeningScreen> {
  bool _loadingCough = false;
  Map<String, dynamic>? _coughResult;

  bool _loadingAnemia = false;
  Map<String, dynamic>? _anemiaResult;

  Future<void> _runCoughAnalysis() async {
    setState(() => _loadingCough = true);
    try {
      final response = await http.post(Uri.parse('http://localhost:8000/api/v1/screening/cough-demo'));
      if (response.statusCode == 200) {
        setState(() {
          _coughResult = jsonDecode(response.body);
        });
      }
    } catch (e) {
      debugPrint('Cough analysis error: $e');
    } finally {
      setState(() => _loadingCough = false);
    }
  }

  Future<void> _runAnemiaScreening(int r, int g, int b) async {
    setState(() => _loadingAnemia = true);
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/api/v1/screening/anemia-colorimetry'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'red': r, 'green': g, 'blue': b}),
      );
      if (response.statusCode == 200) {
        setState(() {
          _anemiaResult = jsonDecode(response.body);
        });
      }
    } catch (e) {
      debugPrint('Anemia error: $e');
    } finally {
      setState(() => _loadingAnemia = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          title: const Text(
            'AI Non-Invasive Screening',
            style: TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            labelColor: Color(0xFF2563EB),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF2563EB),
            tabs: [
              Tab(icon: Icon(Icons.mic), text: "Cough Audio ML"),
              Tab(icon: Icon(Icons.camera_alt), text: "Palmar Anemia RGB"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Cough ML
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.graphic_eq, size: 48, color: Color(0xFF2563EB)),
                        const SizedBox(height: 12),
                        const Text(
                          'Acoustic Cough Biomarker Analysis',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Spectral Centroid & Zero Crossing Rate classifier for wet/dry/whooping cough.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadingCough ? null : _runCoughAnalysis,
                          icon: _loadingCough
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.play_arrow),
                          label: Text(_loadingCough ? 'Analyzing Audio...' : 'Test Cough Spectral Biomarkers'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_coughResult != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Result: ${_coughResult!['cough_type']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('ICD-11: ${_coughResult!['icd_11_code']} | Urgency: ${_coughResult!['triage_urgency']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          const Divider(height: 20),
                          Text('Action: ${_coughResult!['clinical_recommendation']}', style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
                        ],
                      ),
                    )
                  ]
                ],
              ),
            ),

            // Tab 2: Anemia Camera Colorimetry
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.color_lens, size: 48, color: Color(0xFFE11D48)),
                        const SizedBox(height: 12),
                        const Text('Palmar / Conjunctival Hemoglobin Estimator', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            OutlinedButton(onPressed: () => _runAnemiaScreening(185, 125, 120), child: const Text('Healthy Palm')),
                            OutlinedButton(onPressed: () => _runAnemiaScreening(140, 145, 140), child: const Text('Pallor Anemia')),
                          ],
                        )
                      ],
                    ),
                  ),
                  if (_anemiaResult != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hb Estimate: ${_anemiaResult!['estimated_hb_g_dl']} g/dL', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFFE11D48))),
                          Text('Severity: ${_anemiaResult!['anemia_severity']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('Clinical Action: ${_anemiaResult!['clinical_action']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    )
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
