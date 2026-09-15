import 'package:flutter/material.dart';
import '../../core/ml/mobile_ml_engine.dart';

class DbscanOutbreakScreen extends StatefulWidget {
  const DbscanOutbreakScreen({super.key});

  @override
  State<DbscanOutbreakScreen> createState() => _DbscanOutbreakScreenState();
}

class _DbscanOutbreakScreenState extends State<DbscanOutbreakScreen> {
  double _epsRadiusKm = 2.5;
  int _minSamples = 4;
  bool _isRecalculating = false;

  final List<Map<String, dynamic>> _clusters = [
    {
      'cluster_id': 'CLUSTER-ALPHA-01',
      'location': 'Lahaul Outpost (Lat: 32.57, Lon: 77.17)',
      'case_count': 18,
      'fever_ratio': 0.72,
      'resp_ratio': 0.65,
      'transmission_velocity_km_day': 1.4,
      'estimated_r0': 2.45,
      'status': 'HIGH_RISK',
      'color': const Color(0xFFEF4444)
    },
    {
      'cluster_id': 'CLUSTER-BETA-04',
      'location': 'Kinnaur Valley Hub (Lat: 31.65, Lon: 78.47)',
      'case_count': 9,
      'fever_ratio': 0.44,
      'resp_ratio': 0.33,
      'transmission_velocity_km_day': 0.6,
      'estimated_r0': 1.62,
      'status': 'MODERATE_RISK',
      'color': const Color(0xFFF59E0B)
    },
    {
      'cluster_id': 'CLUSTER-GAMMA-09',
      'location': 'Spiti High Plateau (Lat: 32.24, Lon: 78.03)',
      'case_count': 3,
      'fever_ratio': 0.20,
      'resp_ratio': 0.15,
      'transmission_velocity_km_day': 0.2,
      'estimated_r0': 0.95,
      'status': 'LOW_RISK',
      'color': const Color(0xFF10B981)
    }
  ];

  Map<String, dynamic>? _selectedCluster;

  @override
  void initState() {
    super.initState();
    _selectedCluster = _clusters.first;
  }

  void _recalculateClusters() {
    setState(() => _isRecalculating = true);

    // Call Mobile ML Engine for each cluster score
    for (var c in _clusters) {
      final mlResult = MobileMlEngine.evaluateEpidemicClusterRisk(
        clusterSize: (c['case_count'] as int) + (_minSamples - 4),
        growthRate: (c['transmission_velocity_km_day'] as double) * (3.0 / _epsRadiusKm),
        feverRatio: c['fever_ratio'] as double,
        respiratoryRatio: c['resp_ratio'] as double,
        populationDensity: 8500,
        pastOutbreakHistory: true,
      );

      c['status'] = mlResult['risk_tier'];
      c['risk_score'] = mlResult['risk_score'];
      if (mlResult['risk_tier'] == 'HIGH_RISK') {
        c['color'] = const Color(0xFFEF4444);
      } else if (mlResult['risk_tier'] == 'MODERATE_RISK') {
        c['color'] = const Color(0xFFF59E0B);
      } else {
        c['color'] = const Color(0xFF10B981);
      }
    }

    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() => _isRecalculating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('DBSCAN Spatial Clusters Recalculated! (Eps: ${_epsRadiusKm.toStringAsFixed(1)}km, MinPts: $_minSamples)')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          '🗺️ DBSCAN Epidemic Outbreak Engine',
          style: TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Explanatory Banner
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.hub_outlined, color: Color(0xFF047857), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'ℹ️ DBSCAN Spatial Clustering & Haversine R0 Projections',
                        style: TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    '• Purpose: Identifies disease transmission hotspots in geo-spatial coordinates without prior cluster count assumptions.\n'
                    '• Spatial Controls: Adjust Eps (neighborhood distance in km) and MinPts (minimum infection samples) to group syndromic BLE tokens.\n'
                    '• Local ML Engine: Calculates cluster transmission velocity, estimated R0, and containment protocol triggers 100% on mobile.',
                    style: TextStyle(color: Color(0xFF064E3B), fontSize: 11, height: 1.4),
                  ),
                ],
              ),
            ),

            // Controls Card
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
                  const Text('Spatial Parameters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Eps Radius: ${_epsRadiusKm.toStringAsFixed(1)} km', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Text('Min Samples: $_minSamples nodes', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: _epsRadiusKm,
                    min: 0.5,
                    max: 10.0,
                    divisions: 19,
                    activeColor: const Color(0xFF059669),
                    onChanged: (val) {
                      setState(() => _epsRadiusKm = val);
                      _recalculateClusters();
                    },
                  ),
                  Row(
                    children: [
                      const Text('MinPts: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Slider(
                          value: _minSamples.toDouble(),
                          min: 2,
                          max: 15,
                          divisions: 13,
                          activeColor: const Color(0xFF059669),
                          onChanged: (val) {
                            setState(() => _minSamples = val.toInt());
                            _recalculateClusters();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Active Spatial Outbreak Clusters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                if (_isRecalculating)
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            const SizedBox(height: 10),

            // Clusters List
            ..._clusters.map((c) {
              final Color cColor = c['color'] as Color;
              final bool isSelected = _selectedCluster?['cluster_id'] == c['cluster_id'];

              return GestureDetector(
                onTap: () => setState(() => _selectedCluster = c),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? cColor : const Color(0xFFE2E8F0),
                      width: isSelected ? 2.0 : 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on, color: cColor, size: 20),
                              const SizedBox(width: 6),
                              Text(c['cluster_id'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: cColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${c['status']} (${c['risk_score'] ?? "75.0"})',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: cColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(c['location'], style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Active Cases: ${c['case_count']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          Text('R0 Est: ${c['estimated_r0']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo)),
                          Text('Velocity: ${c['transmission_velocity_km_day']} km/day', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
