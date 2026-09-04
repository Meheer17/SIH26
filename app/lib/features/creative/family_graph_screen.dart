import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FamilyGraphScreen extends StatefulWidget {
  const FamilyGraphScreen({super.key});

  @override
  State<FamilyGraphScreen> createState() => _FamilyGraphScreenState();
}

class _FamilyGraphScreenState extends State<FamilyGraphScreen> {
  bool _loading = false;
  Map<String, dynamic>? _graphData;

  Future<void> _fetchGraphDemo() async {
    setState(() => _loading = true);
    try {
      final response = await http.get(Uri.parse('http://localhost:8000/api/v1/mind-family/family-health-graph/demo'));
      if (response.statusCode == 200) {
        setState(() {
          _graphData = jsonDecode(response.body);
        });
      }
    } catch (e) {
      debugPrint('Graph error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchGraphDemo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Family Health Lineage Graph',
          style: TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pedigree Hereditary Risk Calculations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  if (_graphData != null)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: (_graphData!['hereditary_risks'] as List).length,
                      itemBuilder: (context, index) {
                        final item = _graphData!['hereditary_risks'][index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['condition'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text(item['category'], style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                              Text(
                                '${item['estimated_genetic_vulnerability_pct']}%',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF7C3AED)),

                              )
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
}
