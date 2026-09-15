import 'package:flutter/material.dart';

class DisasterEnvironmentTab extends StatefulWidget {
  const DisasterEnvironmentTab({super.key});

  @override
  State<DisasterEnvironmentTab> createState() => _DisasterEnvironmentTabState();
}

class _DisasterEnvironmentTabState extends State<DisasterEnvironmentTab> {
  final List<Map<String, dynamic>> _disasterAlerts = [
    {
      'title': 'Severe Heat-Wave Warning (WBGT Index: 42°C)',
      'category': 'HEAT STRESS ALERT',
      'severity': 'HIGH EXPOSURE RISK',
      'color': const Color(0xFFE11D48),
      'icon': Icons.wb_sunny,
      'desc': 'Extreme heat-stress hazard active. Outdoor workers and elderly must avoid direct sun exposure between 11 AM - 4 PM.',
      'advisory': 'Drink 500ml water every 45 mins. Move to shaded/cooled areas immediately if dizziness occurs.',
    },
    {
      'title': 'Severe Air Quality Alert (AQI 280 - PM2.5 High)',
      'category': 'RESPIRATORY RISK',
      'severity': 'HAZARDOUS AIR',
      'color': const Color(0xFFD97706),
      'icon': Icons.cloud_queue,
      'desc': 'High PM2.5 concentration detected. Vulnerable individuals with asthma/COPD face severe airway irritation.',
      'advisory': 'Wear N95/FFP2 respiratory mask outdoors. Keep air purification active indoors.',
    },
    {
      'title': 'Monsoon Flood & Cyclone Health Advisory',
      'category': 'WATERBORNE RISK',
      'severity': 'PRECAUTIONARY',
      'color': const Color(0xFF0284C7),
      'icon': Icons.water_damage,
      'desc': 'Post-flood standing water risk. Elevated potential for Leptospirosis and Gastroenteritis.',
      'advisory': 'Boil drinking water for 5 minutes. Keep emergency ORS sachets accessible.',
    },
  ];

  final List<Map<String, dynamic>> _environmentalSensors = [
    {'sensor': 'Ambient Temperature', 'val': '41.2 °C', 'status': 'Extreme Ambient Heat', 'icon': Icons.thermostat, 'color': const Color(0xFFE11D48)},
    {'sensor': 'Relative Humidity', 'val': '68%', 'status': 'High Humidity Index', 'icon': Icons.water_drop, 'color': const Color(0xFF0284C7)},
    {'sensor': 'Air Quality Index (AQI)', 'val': '280 AQI', 'status': 'Unhealthy / PM2.5 Peak', 'icon': Icons.air, 'color': const Color(0xFFD97706)},
    {'sensor': 'UV Exposure Index', 'val': '8.5 High', 'status': 'Requires Sun Protection', 'icon': Icons.wb_sunny_outlined, 'color': const Color(0xFF7C3AED)},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Disaster & Environmental Awareness
          _buildDisasterHeader(),
          const SizedBox(height: 20),

          // Environmental Sensor Fusion Readout
          _buildEnvironmentalSensorsGrid(),
          const SizedBox(height: 20),

          // Disaster-Specific Health Alerts
          _buildDisasterAlertsCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDisasterHeader() {
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
              color: const Color(0xFFFFE4E6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFE11D48), size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Disaster & Climate Health Alerts',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE11D48).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('HEAT & AQI ADVISORY ACTIVE', style: TextStyle(color: Color(0xFFE11D48), fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Integrates local temperature, humidity, and AQI sensor data to protect vulnerable populations during extreme Indian weather events.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnvironmentalSensorsGrid() {
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
              Icon(Icons.sensors, color: Color(0xFF0284C7)),
              SizedBox(width: 8),
              Text(
                'Environmental Awareness Sensor Fusion',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: _environmentalSensors.map((s) {
              final color = s['color'] as Color;

              return Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(s['icon'] as IconData, color: color, size: 16),
                      const SizedBox(height: 6),
                      Text(s['val'] as String, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
                      Text(s['sensor'] as String, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      Text(s['status'] as String, style: const TextStyle(fontSize: 8, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDisasterAlertsCard() {
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
              Icon(Icons.notification_important, color: Color(0xFFE11D48)),
              SizedBox(width: 8),
              Text(
                'Disaster-Specific Health Advisories & Alerts',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Column(
            children: _disasterAlerts.map((a) {
              final color = a['color'] as Color;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(radius: 14, backgroundColor: color.withValues(alpha: 0.15), child: Icon(a['icon'] as IconData, color: color, size: 16)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            a['title'] as String,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
                          child: Text(a['severity'] as String, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(a['desc'] as String, style: const TextStyle(fontSize: 11, color: Color(0xFF334155))),
                    const SizedBox(height: 4),
                    Text('💡 Advisory: ${a["advisory"]}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
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
