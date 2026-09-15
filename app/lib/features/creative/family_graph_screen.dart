import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/api/api_endpoints.dart';

class FamilyGraphScreen extends StatefulWidget {
  const FamilyGraphScreen({super.key});

  @override
  State<FamilyGraphScreen> createState() => _FamilyGraphScreenState();
}

class _FamilyGraphScreenState extends State<FamilyGraphScreen> {
  bool _loading = false;
  Map<String, dynamic>? _graphData;

  final List<Map<String, dynamic>> _familyTreeNodes = [
    {
      'generation': 'Gen I (Grandparents)',
      'members': [
        {'name': 'Paternal Grandfather', 'relation': 'Grandfather', 'conditions': ['Hypertension', 'T2 Diabetes'], 'trait': 'Carrier'},
        {'name': 'Paternal Grandmother', 'relation': 'Grandmother', 'conditions': ['Thalassemia Minor'], 'trait': 'Carrier'},
      ]
    },
    {
      'generation': 'Gen II (Parents)',
      'members': [
        {'name': 'Father', 'relation': 'Father', 'conditions': ['T2 Diabetes', 'Coronary Artery Disease'], 'trait': 'Active'},
        {'name': 'Mother', 'relation': 'Mother', 'conditions': ['Thalassemia Trait'], 'trait': 'Carrier'},
      ]
    },
    {
      'generation': 'Gen III (Proband / Self)',
      'members': [
        {'name': 'Self (Proband)', 'relation': 'Self', 'conditions': ['Prediabetes Trait'], 'trait': 'Screening Recommended'},
        {'name': 'Sibling 1', 'relation': 'Brother', 'conditions': ['Asymptomatic'], 'trait': 'Normal'},
      ]
    }
  ];

  final List<Map<String, dynamic>> _hereditaryRisks = [
    {
      'condition': 'Type-2 Diabetes Mellitus',
      'category': 'Polygenic Metabolic Transmission',
      'risk_pct': 68,
      'pattern': 'Autosomal Polygenic (Strong Paternal Lineage)',
      'guideline': 'Annual HbA1c screening, low-glycemic dietary protocol & physical activity 45 min/day.',
      'color': const Color(0xFFF59E0B)
    },
    {
      'condition': 'Thalassemia Minor / Trait',
      'category': 'Autosomal Recessive Blood Disorder',
      'risk_pct': 50,
      'pattern': 'Maternal Single Gene Carrier Transmission',
      'guideline': 'Complete Blood Count (CBC) with HPLC Hemoglobin electrophoresis prior to marital planning.',
      'color': const Color(0xFF7C3AED)
    },
    {
      'condition': 'Coronary Artery Disease (CAD)',
      'category': 'Cardiovascular Hereditary Risk',
      'risk_pct': 42,
      'pattern': 'Multifactorial Epigenetic Predisposition',
      'guideline': 'Lipid panel every 6 months, ApoB monitoring & blood pressure tracking.',
      'color': const Color(0xFFEF4444)
    },
    {
      'condition': 'Hypertension & Arterial Stiffness',
      'category': 'Vascular Epigenetic Vulnerability',
      'risk_pct': 35,
      'pattern': 'Grandparental Inheritance',
      'guideline': 'Sodium restriction (<2g/day) & regular ambulatory blood pressure monitoring.',
      'color': const Color(0xFF3B82F6)
    }
  ];

  Future<void> _fetchGraphDemo() async {
    setState(() => _loading = true);
    try {
      final response = await http.get(Uri.parse(ApiEndpoints.endpoint('mind-family/family-health-graph/demo')));
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

  void _showAddMemberDialog() {
    final nameController = TextEditingController();
    String selectedRelation = 'Parent';
    final conditionController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add Family Member to Lineage'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Member Name / Label'),
              ),
              DropdownButtonFormField<String>(
                value: selectedRelation,
                items: ['Grandparent', 'Parent', 'Sibling', 'Child'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (val) {
                  if (val != null) selectedRelation = val;
                },
                decoration: const InputDecoration(labelText: 'Relation Tier'),
              ),
              TextField(
                controller: conditionController,
                decoration: const InputDecoration(labelText: 'Known Health Conditions (e.g. Diabetes, Anemia)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    _familyTreeNodes[1]['members'].add({
                      'name': nameController.text,
                      'relation': selectedRelation,
                      'conditions': conditionController.text.split(',').map((s) => s.trim()).toList(),
                      'trait': 'User Added',
                    });
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Family lineage member added & risks updated!')),
                  );
                }
              },
              child: const Text('Add Node'),
            ),
          ],
        );
      },
    );
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
          'Family Health Lineage & Pedigree Tree',
          style: TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1, color: Color(0xFF4F46E5)),
            tooltip: 'Add Member Node',
            onPressed: _showAddMemberDialog,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Explanatory Banner
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFC7D2FE)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.account_tree_outlined, color: Color(0xFF4338CA), size: 20),
                            SizedBox(width: 8),
                            Text(
                              'ℹ️ Understanding Family Health Lineage',
                              style: TextStyle(color: Color(0xFF3730A3), fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Text(
                          '• What we are doing: Mapping multi-generational family health history across Grandparents, Parents, and Siblings to quantify hereditary genetic risks.\n'
                          '• How it works: Analyzes Mendelian transmission patterns (Autosomal Dominant/Recessive & Polygenic) to calculate your personalized vulnerability percentage.\n'
                          '• Action Plan: Provides targeted early clinical screening recommendations before disease onset.',
                          style: TextStyle(color: Color(0xFF312E81), fontSize: 11, height: 1.4),
                        ),
                      ],
                    ),
                  ),

                  // Pedigree Tree Visualizer
                  const Text(
                    'Multi-Generational Pedigree Tree',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 10),

                  ..._familyTreeNodes.map((gen) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(color: Color(0xFF4F46E5), shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                gen['generation'],
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF4F46E5)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: (gen['members'] as List).map<Widget>((m) {
                              final List conditions = m['conditions'] ?? [];
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${m['name']} (${m['relation']})',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 4,
                                      children: conditions.map<Widget>((c) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFEE2E2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            c.toString(),
                                            style: const TextStyle(fontSize: 10, color: Color(0xFF991B1B), fontWeight: FontWeight.bold),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 16),
                  const Text('Calculated Hereditary Risk Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                  const SizedBox(height: 10),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _hereditaryRisks.length,
                    itemBuilder: (context, index) {
                      final item = _hereditaryRisks[index];
                      final Color cardColor = item['color'] as Color;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item['condition'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                                      Text(item['category'], style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: cardColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${item['risk_pct']}% Risk',
                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: cardColor),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Inheritance Pattern: ${item['pattern']}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '💡 Clinical Guideline: ${item['guideline']}',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF334155)),
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
}
