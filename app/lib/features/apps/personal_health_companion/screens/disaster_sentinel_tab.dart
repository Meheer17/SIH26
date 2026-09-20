import 'package:flutter/material.dart';
import '../services/phc_service.dart';

class DisasterSentinelTab extends StatefulWidget {
  const DisasterSentinelTab({super.key});

  @override
  State<DisasterSentinelTab> createState() => _DisasterSentinelTabState();
}

class _DisasterSentinelTabState extends State<DisasterSentinelTab> {
  final PhcService _phcService = PhcService();

  bool _isLoading = true;
  Map<String, dynamic>? _currentEnv;
  Map<String, dynamic>? _forecast;
  List<dynamic> _disasterAlerts = [];

  // Local checklist toggle state
  final Map<String, bool> _checklistState = {};

  @override
  void initState() {
    super.initState();
    _loadDisasterData();
  }

  Future<void> _loadDisasterData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _phcService.getCurrentEnvironment(),
        _phcService.getEnvironmentForecast(),
        _phcService.getDisasterAlerts(),
      ]);

      if (mounted) {
        setState(() {
          _currentEnv = results[0] as Map<String, dynamic>?;
          _forecast = results[1] as Map<String, dynamic>?;
          _disasterAlerts = results[2] as List<dynamic>? ?? [];
          _isLoading = false;

          // Initialize checklist states
          for (final alert in _disasterAlerts) {
            final list = alert['preparedness_checklist'] as List<dynamic>? ?? [];
            for (var i = 0; i < list.length; i++) {
              final key = '${alert['id']}_$i';
              if (!_checklistState.containsKey(key)) {
                _checklistState[key] = list[i]['completed'] == true;
              }
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading disaster data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFD97706)));
    }

    final temp = _currentEnv?['ambient_temp_c'] ?? 41.5;
    final feelsLike = _currentEnv?['feels_like_c'] ?? 47.1;
    final humidity = _currentEnv?['humidity_pct'] ?? 64.0;
    final aqi = _currentEnv?['aqi'] ?? 288;
    final aqiCategory = _currentEnv?['aqi_category'] ?? 'Very Poor';
    final uv = _currentEnv?['uv_index'] ?? 9.2;
    final uvSeverity = _currentEnv?['uv_severity'] ?? 'Very High';
    final wetBulb = _currentEnv?['wet_bulb_temp_c'] ?? 33.2;
    final locationName = _currentEnv?['location_name'] ?? 'Varanasi (Assi - BHU Zone)';
    final pollutants = _currentEnv?['pollutants'] as Map<String, dynamic>? ?? {};

    return RefreshIndicator(
      onRefresh: _loadDisasterData,
      color: const Color(0xFFD97706),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Location & Extreme Weather Banner
            _buildLocationBanner(locationName),
            const SizedBox(height: 16),

            // Environmental Sensor Fusion 4-Grid Readout
            const Text(
              'HYPERLOCAL ENVIRONMENTAL SENSOR FUSION',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 0.8),
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _buildEnvSensorCard(
                  title: 'Ambient Temperature',
                  value: '$temp °C',
                  subtext: 'Feels Like $feelsLike°C (RH: $humidity%)',
                  icon: Icons.wb_sunny,
                  color: const Color(0xFFE11D48),
                  badge: 'Extreme Heat',
                ),
                _buildEnvSensorCard(
                  title: 'Air Quality (AQI)',
                  value: '$aqi AQI',
                  subtext: aqiCategory,
                  icon: Icons.air,
                  color: const Color(0xFFD97706),
                  badge: 'PM2.5 Peak',
                ),
                _buildEnvSensorCard(
                  title: 'Wet-Bulb Temp (WBGT)',
                  value: '$wetBulb °C',
                  subtext: 'Dangerous Exertion Index',
                  icon: Icons.water_drop,
                  color: const Color(0xFF0284C7),
                  badge: 'Heatstroke Risk',
                ),
                _buildEnvSensorCard(
                  title: 'UV Solar Radiation',
                  value: '$uv Index',
                  subtext: uvSeverity,
                  icon: Icons.flare,
                  color: const Color(0xFF7C3AED),
                  badge: 'Sun Protection Req',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // AQI Pollutant Chemical Breakdown Card
            _buildPollutantsCard(pollutants),
            const SizedBox(height: 20),

            // Section: Active Disaster & Government Health Advisories
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ACTIVE DISASTER & HEALTH ADVISORIES',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 0.8),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(10)),
                  child: const Text('IMD / NDMA Live', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Disaster Alerts Feed with Actionable Checklist
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _disasterAlerts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (context, idx) {
                final alert = _disasterAlerts[idx];
                return _buildDisasterAlertCard(alert);
              },
            ),
            const SizedBox(height: 20),

            // 24-Hour Timeline Forecast
            _buildForecastTimeline(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationBanner(String location) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x060F172A), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Color(0xFFE11D48)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'IMD Orange Alert Active • 72-Hour Heatwave Protocol Enacted',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnvSensorCard({
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color color,
    required String badge,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x060F172A), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(badge, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              Text(title, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
            ],
          ),
          Text(subtext, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildPollutantsCard(Map<String, dynamic> pol) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x060F172A), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('ATMOSPHERIC POLLUTANT CHEMICAL BREAKDOWN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              Text('CPCB CAAQMS', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildGasIndicator('PM2.5', '${pol['pm2_5'] ?? 198}', 'µg/m³', const Color(0xFFE11D48)),
              _buildGasIndicator('PM10', '${pol['pm10'] ?? 295}', 'µg/m³', const Color(0xFFD97706)),
              _buildGasIndicator('NO₂', '${pol['no2'] ?? 42}', 'µg/m³', const Color(0xFF0284C7)),
              _buildGasIndicator('SO₂', '${pol['so2'] ?? 14}', 'µg/m³', const Color(0xFF059669)),
              _buildGasIndicator('CO', '${pol['co'] ?? 1.4}', 'mg/m³', const Color(0xFF7C3AED)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGasIndicator(String name, String value, String unit, Color color) {
    return Column(
      children: [
        Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
        Text(unit, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
      ],
    );
  }

  Widget _buildDisasterAlertCard(dynamic alert) {
    final title = alert['title'] ?? '';
    final agency = alert['agency'] ?? '';
    final severity = alert['severity'] ?? '';
    final impacts = alert['health_impacts'] as List<dynamic>? ?? [];
    final advisories = alert['actionable_advisories'] as List<dynamic>? ?? [];
    final checklist = alert['preparedness_checklist'] as List<dynamic>? ?? [];
    final alertId = alert['id'] ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x060F172A), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(6)),
                child: Text(severity, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              Text(agency, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 8),

          // Health Impacts
          const Text('Clinical Health Impacts:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
          const SizedBox(height: 4),
          ...impacts.map((imp) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(color: Color(0xFFE11D48), fontWeight: FontWeight.bold)),
                Expanded(child: Text('$imp', style: const TextStyle(fontSize: 11, color: Color(0xFF475569)))),
              ],
            ),
          )),
          const SizedBox(height: 10),

          // Actionable Field Advisories
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.health_and_safety, size: 16, color: Color(0xFF15803D)),
                    SizedBox(width: 6),
                    Text('Actionable Protection Protocols:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                  ],
                ),
                const SizedBox(height: 6),
                ...advisories.map((adv) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check, size: 12, color: Color(0xFF15803D)),
                      const SizedBox(width: 6),
                      Expanded(child: Text('$adv', style: const TextStyle(fontSize: 11, color: Color(0xFF166534), fontWeight: FontWeight.w600))),
                    ],
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Preparedness Checklist
          if (checklist.isNotEmpty) ...[
            const Text('Personal Readiness Checklist:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
            const SizedBox(height: 4),
            ...List.generate(checklist.length, (idx) {
              final key = '${alertId}_$idx';
              final isDone = _checklistState[key] ?? false;
              final itemText = checklist[idx]['item'] ?? '';
              return CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: const Color(0xFFD97706),
                title: Text(
                  itemText,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDone ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                value: isDone,
                onChanged: (val) {
                  setState(() {
                    _checklistState[key] = val ?? false;
                  });
                },
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildForecastTimeline() {
    final hours = _forecast?['forecast_hours'] as List<dynamic>? ?? [];
    if (hours.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x060F172A), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('24-HOUR THERMAL & AQI FORECAST', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              Text('IMD Microclimate Model', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 95,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: hours.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, idx) {
                final h = hours[idx];
                final isExtreme = (h['heat_risk'] ?? '') == 'EXTREME' || (h['heat_risk'] ?? '') == 'DANGER';
                return Container(
                  width: 90,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isExtreme ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isExtreme ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(h['hour'] ?? '', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                      Text('${h['temp_c']}°C', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: isExtreme ? const Color(0xFFDC2626) : const Color(0xFF0F172A))),
                      Text('AQI ${h['aqi']}', style: const TextStyle(fontSize: 10, color: Color(0xFFD97706), fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
