import 'package:flutter/material.dart';

class DashboardEmergencyTab extends StatefulWidget {
  const DashboardEmergencyTab({super.key});

  @override
  State<DashboardEmergencyTab> createState() => _DashboardEmergencyTabState();
}

class _DashboardEmergencyTabState extends State<DashboardEmergencyTab> {
  bool _fallDetectionActive = true;
  bool _sosAlertTriggered = false;
  bool _locationSharingPermitted = true;

  final List<int> _dailyHealthScores = [85, 82, 78, 88, 84, 80, 86];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Wellness Dashboard & Emergency Assist
          _buildDashboardHeader(),
          const SizedBox(height: 20),

          // Fall Detection & Emergency SOS Trigger Card
          _buildEmergencySosCard(),
          const SizedBox(height: 20),

          // Daily Health Summary & 7-Day Trend Analysis
          _buildWellnessTrendCard(),
          const SizedBox(height: 20),

          // Personalized Actionable Recommendations
          _buildRecommendationsCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDashboardHeader() {
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
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.dashboard_outlined, color: Color(0xFF0284C7), size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Personal Wellness & Emergency Hub',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('FALL SENSOR ACTIVE', style: TextStyle(color: Color(0xFF0284C7), fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Daily health summaries, stress risk gauges, automatic fall detection, and location-enabled emergency SOS alerts.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencySosCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _sosAlertTriggered ? const Color(0xFFFFF1F2) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _sosAlertTriggered ? const Color(0xFFFECDD3) : const Color(0xFFE2E8F0)),
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
                  Icon(Icons.sos, color: Color(0xFFE11D48), size: 28),
                  SizedBox(width: 8),
                  Text(
                    'Automatic Fall & Medical SOS Dispatch',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              Switch(
                value: _fallDetectionActive,
                activeTrackColor: const Color(0xFFE11D48),
                onChanged: (v) => setState(() => _fallDetectionActive = v),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Accelerometer & gyroscope sensors continuously detect sudden falls or medical distress, alerting family caregivers and emergency services.',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),

          if (_sosAlertTriggered) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFE11D48), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: const [
                  Icon(Icons.warning, color: Colors.white),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'EMERGENCY SOS DISPATCHED! Caregiver & Local Disaster Cell notified with current GPS coordinates (25.3176° N, 82.9739° E).',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE11D48),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.sos_outlined, size: 18),
                  label: Text(_sosAlertTriggered ? 'CANCEL SOS ALERT' : 'TRIGGER EMERGENCY SOS NOW', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    setState(() {
                      _sosAlertTriggered = !_sosAlertTriggered;
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: Icon(_locationSharingPermitted ? Icons.location_on : Icons.location_off, color: const Color(0xFF0284C7)),
                tooltip: 'Toggle GPS Sharing',
                onPressed: () {
                  setState(() {
                    _locationSharingPermitted = !_locationSharingPermitted;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWellnessTrendCard() {
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
              Icon(Icons.show_chart, color: Color(0xFF059669)),
              SizedBox(width: 8),
              Text(
                '7-Day Personal Wellness Score Trend',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(_dailyHealthScores.length, (idx) {
              final score = _dailyHealthScores[idx];
              final color = score > 80 ? const Color(0xFF059669) : const Color(0xFFD97706);

              return Column(
                children: [
                  Text('$score', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                  const SizedBox(height: 4),
                  Container(
                    width: 24,
                    height: (score * 0.7).toDouble(),
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                  ),
                  const SizedBox(height: 6),
                  Text(['M', 'T', 'W', 'T', 'F', 'S', 'S'][idx], style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    final recs = [
      {'title': 'Hydration Advisory', 'desc': 'Drink 3.5 Liters of water + ORS electrolyte due to 41°C heat wave.', 'icon': Icons.water_drop, 'color': const Color(0xFF0284C7)},
      {'title': 'Outdoor Rest Pause', 'desc': 'Take a 15-min cooling pause every 2 hours of outdoor manual work.', 'icon': Icons.timer, 'color': const Color(0xFFD97706)},
      {'title': 'Air Quality Precaution', 'desc': 'Wear N95 mask outdoors due to 280 AQI PM2.5 elevation.', 'icon': Icons.air, 'color': const Color(0xFF7C3AED)},
    ];

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
              Icon(Icons.lightbulb_outline, color: Color(0xFFD97706)),
              SizedBox(width: 8),
              Text(
                'Personalized Actionable Recommendations',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Column(
            children: recs.map((r) {
              final color = r['color'] as Color;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: Row(
                  children: [
                    CircleAvatar(radius: 14, backgroundColor: color.withValues(alpha: 0.15), child: Icon(r['icon'] as IconData, color: color, size: 16)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r['title'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          Text(r['desc'] as String, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
