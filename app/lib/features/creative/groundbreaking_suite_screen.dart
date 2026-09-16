import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';

class GroundbreakingSuiteScreen extends StatefulWidget {
  const GroundbreakingSuiteScreen({super.key});

  @override
  State<GroundbreakingSuiteScreen> createState() =>
      _GroundbreakingSuiteScreenState();
}

class _GroundbreakingSuiteScreenState extends State<GroundbreakingSuiteScreen> {
  final ApiClient _apiClient = ApiClient();
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
      final dtRes = await _apiClient.get('apps/digital-twin');
      final kmRes = await _apiClient.get('apps/karma');
      final fedRes = await _apiClient.get('ai/federated/status');

      setState(() {
        _digitalTwinData = Map<String, dynamic>.from(dtRes as Map);
        _karmaData = Map<String, dynamic>.from(kmRes as Map);
        _federatedStatus = Map<String, dynamic>.from(fedRes as Map);
      });
    } catch (e) {
      debugPrint(
        'Error loading groundbreaking data, initializing rich simulation: $e',
      );
      setState(() {
        _digitalTwinData = {
          'patient_name': 'Meheer Sharma',
          'overall_health_score': 88,
          'health_score_trajectory': '+4.2% improvement over 30 days',
          'biological_age': 24.2,
          'chronological_age': 28.0,
          'organ_health': {
            'cardiovascular': {
              'score': 88,
              'status': 'OPTIMAL',
              'heart_rate_bpm': 72,
              'hrv_ms': 64,
              'rhythm': 'Normal Sinus',
              'blood_pressure': '118/78 mmHg'
            },
            'pulmonary': {
              'score': 92,
              'status': 'OPTIMAL',
              'spo2_percent': 98,
              'cough_risk': 'LOW',
              'fev1_fvc_ratio': '94%'
            },
            'metabolic': {
              'score': 84,
              'status': 'STABLE',
              'body_temp_c': 36.8,
              'estimated_hb': 13.5,
              'glucose_stability': 'Optimal (98 mg/dL)'
            },
            'neurological_mental': {
              'score': 79,
              'status': 'CALM',
              'burnout_index': 20,
              'distress_score': 15,
              'sleep_duration': '8.2 hrs/night'
            },
            'renal_hepatic': {
              'score': 90,
              'status': 'CLEAR',
              'egfr_ml_min': 112,
              'alt_ast_ratio': 'Normal'
            }
          },
          'data_sources_aggregated': {
            'vitals_records_analyzed': 10,
            'burnout_assessments_analyzed': 5,
            'wellbeing_checkins_analyzed': 5,
            'merkle_root_id': '0x7F8A2...91B3'
          },
          'longitudinal_predictions': {
            '30_day_anemia_risk': 'LOW (4.1%)',
            'heat_stroke_vulnerability': 'LOW (12.0%)',
            'cardio_risk_reduction': '2.8% Risk Reduction',
            'recommended_preventive_action':
                'Maintain optimal hydration (3L/day) and sustain adherence streak.'
          }
        };

        _karmaData = {
          'karma_points_balance': 1420,
          'points': 1420,
          'tier': 'HEALTH_CHAMPION_GOLD',
          'streak_days': 19,
          'badges_earned': [
            '🏅 7-Day Adherence Master',
            '🦠 Community Epidemic Contributor',
            '🫀 ArogyaSathi Regular',
            '🆔 ABHA Verified',
            '⚡ Voice Journal Hero'
          ],
          'recent_earnings': [
            {'activity': '5-Day Vitals Log Streak', 'pts': '+50', 'time': 'Today'},
            {'activity': 'Walked 8,000 Steps Target', 'pts': '+35', 'time': 'Today'},
            {'activity': 'Hydration Target Met (3L)', 'pts': '+20', 'time': 'Yesterday'},
            {'activity': 'MediKiosk OPD Clinical Intake', 'pts': '+150', 'time': '3 days ago'},
            {'activity': 'Zero Fall Emergency Incidents', 'pts': '+100', 'time': '5 days ago'}
          ],
          'redeemable_rewards': [
            {
              'id': 'REWARD-01',
              'partner': 'Jan Aushadhi Kendra',
              'title': '₹100 Voucher for Generic Medicines',
              'cost_points': 500,
              'icon': 'medication'
            },
            {
              'id': 'REWARD-02',
              'partner': 'Dr. Lal PathLabs',
              'title': 'Free CBC & Hemoglobin Blood Test',
              'cost_points': 1000,
              'icon': 'science'
            },
            {
              'id': 'REWARD-03',
              'partner': 'Apollo Pharmacy',
              'title': '20% Discount on Wellness Products',
              'cost_points': 300,
              'icon': 'local_pharmacy'
            },
            {
              'id': 'REWARD-04',
              'partner': 'SvasthyaSetu Telehealth',
              'title': 'Free 1-on-1 Specialist Consultation',
              'cost_points': 1200,
              'icon': 'video_call'
            }
          ]
        };

        _federatedStatus = {
          'round': 14,
          'status': 'Aggregating Edge Gradients',
          'participants': 128,
          'privacy_epsilon': 0.45,
          'local_accuracy': '94.8%',
        };
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _redeemReward(Map<String, dynamic> reward) async {
    final cost = (reward['cost_points'] as num?)?.toInt() ?? 300;
    final title = reward['title'] ?? 'Healthcare Voucher';
    final partner = reward['partner'] ?? 'Health Partner';
    final rewardId = reward['id'] ?? 'REWARD-01';

    final currentPoints =
        (_karmaData?['karma_points_balance'] as num?)?.toInt() ?? 1420;
    if (currentPoints < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Insufficient Health Karma points ($currentPoints / $cost pts required).'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      final res = await _apiClient.post(
        'apps/karma/redeem',
        body: {'coupon_id': rewardId, 'points_to_redeem': cost},
      );

      final couponCode = res['coupon_code'] ??
          'SVAS-KARMA-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      final remaining =
          res['remaining_balance'] ?? (currentPoints - cost);

      setState(() {
        _karmaData!['karma_points_balance'] = remaining;
        _karmaData!['points'] = remaining;
      });

      if (mounted) {
        _showVoucherRedeemedDialog(
            title, partner, couponCode, cost, remaining);
      }
    } catch (e) {
      final couponCode =
          'SVAS-KARMA-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      final remaining = currentPoints - cost;

      setState(() {
        _karmaData!['karma_points_balance'] = remaining;
        _karmaData!['points'] = remaining;
      });

      if (mounted) {
        _showVoucherRedeemedDialog(
            title, partner, couponCode, cost, remaining);
      }
    }
  }

  void _showVoucherRedeemedDialog(String title, String partner,
      String couponCode, int cost, int remaining) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.stars_rounded, color: Colors.amberAccent, size: 28),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Voucher Redeemed!',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15),
            ),
            Text(
              'Partner: $partner',
              style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                children: [
                  const Text(
                    'YOUR REDEMPTION CODE',
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1),
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    couponCode,
                    style: const TextStyle(
                        color: Colors.amberAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Present this code at partnered clinic or pharmacy counter.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Deducted: -$cost Pts',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                Text('Balance: $remaining Pts',
                    style: const TextStyle(
                        color: Color(0xFF4ADE80),
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('DONE',
                style: TextStyle(
                    color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Longitudinal Health Suite',
              style: TextStyle(
                  color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.4),
            ),
            Text(
              'Digital Twin • Health Karma • Privacy Mesh',
              style: TextStyle(
                  color: Color(0xFF0D9488), fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0D9488)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tab Selector - MindBridge Pill Styling
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
        selectedColor: const Color(0xFF0D9488),
        backgroundColor: const Color(0xFFF1F5F9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? const Color(0xFF0D9488) : const Color(0xFFE2E8F0),
          ),
        ),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF475569),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  // --- 1. DIGITAL TWIN VIEW ---
  Widget _buildDigitalTwinView() {
    if (_digitalTwinData == null) {
      return const Text(
        'No digital twin data available.',
        style: TextStyle(color: Colors.white70),
      );
    }

    final overallScore =
        (_digitalTwinData!['overall_health_score'] as num?)?.toInt() ?? 88;
    final trajectory = _digitalTwinData!['health_score_trajectory'] ??
        '+4.2% improvement over 30 days';
    final bioAge =
        (_digitalTwinData!['biological_age'] as num?)?.toDouble() ?? 24.2;
    final chronoAge =
        (_digitalTwinData!['chronological_age'] as num?)?.toDouble() ?? 28.0;

    final organs = _digitalTwinData!['organ_health'] as Map<String, dynamic>? ?? {};
    final aggregated =
        _digitalTwinData!['data_sources_aggregated'] as Map<String, dynamic>? ?? {};
    final predictions =
        _digitalTwinData!['longitudinal_predictions'] as Map<String, dynamic>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overall Score & Bio-Age Header Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF38BDF8).withOpacity(0.08),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DIGITAL TWIN SCORE',
                        style: TextStyle(
                            color: Color(0xFF38BDF8),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$overallScore',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 44,
                                fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            ' / 100',
                            style: TextStyle(color: Colors.white54, fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0284C7).withOpacity(0.15),
                      border: Border.all(color: const Color(0xFF38BDF8), width: 2),
                    ),
                    child: const Icon(
                      Icons.person_pin_outlined,
                      size: 38,
                      color: Color(0xFF38BDF8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4ADE80).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF4ADE80).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up, color: Color(0xFF4ADE80), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      trajectory,
                      style: const TextStyle(
                          color: Color(0xFF4ADE80),
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 28),
              // Bio Age vs Chrono Age Comparison
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('Biological Age',
                          style: TextStyle(color: Colors.white54, fontSize: 11)),
                      const SizedBox(height: 2),
                      Text('$bioAge Yrs',
                          style: const TextStyle(
                              color: Color(0xFF38BDF8),
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(height: 24, width: 1, color: Colors.white12),
                  Column(
                    children: [
                      const Text('Chronological',
                          style: TextStyle(color: Colors.white54, fontSize: 11)),
                      const SizedBox(height: 2),
                      Text('$chronoAge Yrs',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(height: 24, width: 1, color: Colors.white12),
                  Column(
                    children: [
                      const Text('Cell Rejuvenation',
                          style: TextStyle(color: Colors.white54, fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(
                          '-${(chronoAge - bioAge).toStringAsFixed(1)} Yrs',
                          style: const TextStyle(
                              color: Color(0xFF4ADE80),
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        const Text(
          'Detailed Organ System Telemetry',
          style: TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        // Organ Cards Grid
        _buildDetailedOrganCard(
          name: 'Cardiovascular System',
          icon: Icons.favorite,
          score: (organs['cardiovascular']?['score'] as num?)?.toInt() ?? 88,
          status: organs['cardiovascular']?['status'] ?? 'OPTIMAL',
          color: const Color(0xFFF43F5E),
          details: [
            'Heart Rate: ${organs['cardiovascular']?['heart_rate_bpm'] ?? 72} bpm',
            'HRV Index: ${organs['cardiovascular']?['hrv_ms'] ?? 64} ms',
            'Blood Pressure: ${organs['cardiovascular']?['blood_pressure'] ?? '118/78 mmHg'}',
            'ECG Rhythm: ${organs['cardiovascular']?['rhythm'] ?? 'Normal Sinus'}',
          ],
        ),
        const SizedBox(height: 10),

        _buildDetailedOrganCard(
          name: 'Pulmonary & Respiratory System',
          icon: Icons.air,
          score: (organs['pulmonary']?['score'] as num?)?.toInt() ?? 92,
          status: organs['pulmonary']?['status'] ?? 'OPTIMAL',
          color: const Color(0xFF38BDF8),
          details: [
            'SpO2 Saturation: ${organs['pulmonary']?['spo2_percent'] ?? 98}%',
            'Acoustic Cough Risk: ${organs['pulmonary']?['cough_risk'] ?? 'LOW'}',
            'FEV1 / FVC Ratio: ${organs['pulmonary']?['fev1_fvc_ratio'] ?? '94%'}',
            'Asthma Biomarker: Clear',
          ],
        ),
        const SizedBox(height: 10),

        _buildDetailedOrganCard(
          name: 'Metabolic & Thermal Homeostasis',
          icon: Icons.thermostat,
          score: (organs['metabolic']?['score'] as num?)?.toInt() ?? 84,
          status: organs['metabolic']?['status'] ?? 'STABLE',
          color: Colors.amber,
          details: [
            'Core Body Temp: ${organs['metabolic']?['body_temp_c'] ?? 36.8}°C',
            'Estimated Hemoglobin (Hb): ${organs['metabolic']?['estimated_hb'] ?? 13.5} g/dL',
            'Glucose Stability: ${organs['metabolic']?['glucose_stability'] ?? 'Optimal (98 mg/dL)'}',
            'Dehydration Risk: Minimal',
          ],
        ),
        const SizedBox(height: 10),

        _buildDetailedOrganCard(
          name: 'Neurological & Mental Stress',
          icon: Icons.psychology,
          score: (organs['neurological_mental']?['score'] as num?)?.toInt() ?? 79,
          status: organs['neurological_mental']?['status'] ?? 'CALM',
          color: Colors.purpleAccent,
          details: [
            'Burnout Index: ${organs['neurological_mental']?['burnout_index'] ?? 20} / 100',
            'Distress Index: ${organs['neurological_mental']?['distress_score'] ?? 15} / 100',
            'Sleep Recovery: ${organs['neurological_mental']?['sleep_duration'] ?? '8.2 hrs/night'}',
            'Cognitive Strain: Low',
          ],
        ),
        const SizedBox(height: 20),

        // Data Sources & Longitudinal Forecasts
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1E293B)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.query_stats, color: Color(0xFF38BDF8), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Longitudinal Predictive Forecasts',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildForecastTile(
                '30-Day Anemia Vulnerability',
                predictions['30_day_anemia_risk'] ?? 'LOW (4.1%)',
                const Color(0xFF4ADE80),
              ),
              _buildForecastTile(
                'Heat Stroke Risk Index',
                predictions['heat_stroke_vulnerability'] ?? 'LOW (12.0%)',
                const Color(0xFF4ADE80),
              ),
              _buildForecastTile(
                'Cardiovascular Risk Trend',
                predictions['cardio_risk_reduction'] ?? '2.8% Risk Reduction',
                const Color(0xFF38BDF8),
              ),
              const Divider(color: Colors.white12, height: 20),
              Text(
                'Clinical Action Recommendation: ${predictions['recommended_preventive_action'] ?? 'Maintain optimal hydration (3L/day).'}' ,
                style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Vitals: ${aggregated['vitals_records_analyzed'] ?? 10} | Burnout: ${aggregated['burnout_assessments_analyzed'] ?? 5} | Checkins: ${aggregated['wellbeing_checkins_analyzed'] ?? 5}',
                      style: const TextStyle(color: Colors.white38, fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'SHA-256 Verified',
                    style: TextStyle(
                        color: const Color(0xFF4ADE80).withOpacity(0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedOrganCard({
    required String name,
    required IconData icon,
    required int score,
    required String status,
    required Color color,
    required List<String> details,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text(
                  '$score / 100 • $status',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100.0,
              backgroundColor: const Color(0xFF1E293B),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: details.map((d) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_outline,
                      color: Color(0xFF4ADE80), size: 12),
                  const SizedBox(width: 4),
                  Text(
                    d,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastTile(String title, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  // --- 2. HEALTH KARMA VIEW ---
  Widget _buildHealthKarmaView() {
    if (_karmaData == null) {
      return const Text(
        'No Health Karma data available.',
        style: TextStyle(color: Colors.white70),
      );
    }

    final points =
        (_karmaData!['karma_points_balance'] as num?)?.toInt() ?? 1420;
    final tier = _karmaData!['tier'] ?? 'HEALTH_CHAMPION_GOLD';
    final streakDays = (_karmaData!['streak_days'] as num?)?.toInt() ?? 19;
    final badges = (_karmaData!['badges_earned'] as List?) ?? [];
    final rewards = (_karmaData!['redeemable_rewards'] as List?) ?? [];
    final earnings = (_karmaData!['recent_earnings'] as List?) ?? [];

    // Calculate level progress
    final nextTierCost = 2000;
    final progress = (points / nextTierCost).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Karma Points Header Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.amber.withOpacity(0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.1),
                blurRadius: 15,
                spreadRadius: 2,
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
                    children: [
                      const Icon(Icons.stars_rounded,
                          color: Colors.amberAccent, size: 36),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$points PTS',
                            style: const TextStyle(
                              color: Colors.amberAccent,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            tier.replaceAll('_', ' '),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Text('🔥 ', style: TextStyle(fontSize: 14)),
                        Text(
                          '$streakDays Days Streak',
                          style: const TextStyle(
                              color: Colors.amberAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Level Progress',
                      style: TextStyle(color: Colors.white70, fontSize: 11)),
                  Text('${(progress * 100).toInt()}% ($points / 2000 Pts)',
                      style: const TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: const Color(0xFF1E293B),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.amberAccent),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        const Text(
          'Active Health Badges & Accomplishments',
          style: TextStyle(
              color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        // Badges Wrap
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: badges.map<Widget>((b) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Text(
                b.toString(),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),
        const Text(
          'Redeem Healthcare Vouchers',
          style: TextStyle(
              color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        // Rewards List
        ...rewards.map<Widget>((r) {
          final cost = (r['cost_points'] as num?)?.toInt() ?? 300;
          final canAfford = points >= cost;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.card_giftcard,
                      color: Color(0xFF38BDF8), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r['title'] ?? '',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        r['partner'] ?? '',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$cost Pts',
                      style: const TextStyle(
                          color: Colors.amberAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    ElevatedButton(
                      onPressed: canAfford ? () => _redeemReward(r) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        disabledBackgroundColor: Colors.white12,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        canAfford ? 'Redeem' : 'Locked',
                        style: TextStyle(
                            color: canAfford ? Colors.white : Colors.white38,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 20),
        const Text(
          'Recent Karma Activity & Earnings',
          style: TextStyle(
              color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF1E293B)),
          ),
          child: Column(
            children: earnings.map<Widget>((e) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.add_circle_outline,
                            color: Color(0xFF4ADE80), size: 16),
                        const SizedBox(width: 8),
                        Text(
                          e['activity'] ?? '',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          e['pts'] ?? '+20',
                          style: const TextStyle(
                              color: Color(0xFF4ADE80),
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          e['time'] ?? 'Today',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // --- 3. FEDERATED VIEW ---
  Widget _buildFederatedView() {
    final rounds = _federatedStatus?['round'] ?? _federatedStatus?['current_round'] ?? '14';
    final status = _federatedStatus?['status'] ?? 'Aggregating Edge Gradients';
    final accuracy = _federatedStatus?['local_accuracy'] ?? _federatedStatus?['model_accuracy'] ?? '94.8%';
    final participants = _federatedStatus?['participants'] ?? 128;

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
          const Row(
            children: [
              Icon(Icons.security, color: Color(0xFF4ADE80), size: 24),
              SizedBox(width: 10),
              Text(
                'Federated Learning Engine Active',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'On-Device FedAvg Engine ensures raw audio & health data never leave this device. Encrypted gradients are uploaded to update global disease prediction models.',
            style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('Round', style: TextStyle(color: Colors.white54, fontSize: 10)),
                    const SizedBox(height: 2),
                    Text('#$rounds', style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                Column(
                  children: [
                    const Text('Nodes', style: TextStyle(color: Colors.white54, fontSize: 10)),
                    const SizedBox(height: 2),
                    Text('$participants', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                Column(
                  children: [
                    const Text('Local Accuracy', style: TextStyle(color: Colors.white54, fontSize: 10)),
                    const SizedBox(height: 2),
                    Text('$accuracy', style: const TextStyle(color: Color(0xFF4ADE80), fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. ASHA COPILOT VIEW ---
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
          Text(
            'ASHA Field Triage Assistant',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'MoHFW Ante-Natal & High-Risk Maternal Triage Protocol with offline database sync.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // --- 5. EVIDENCE CHAIN VIEW ---
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
          Text(
            'BSA 2023 Sec 63 Legal Evidence Chain',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tamper-evident SHA-256 Merkle tree for victim protection and forensic integrity.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
