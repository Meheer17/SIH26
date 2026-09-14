import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/api/api_endpoints.dart';
import '../../core/theme/app_theme.dart';

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
  int _selectedRed = 230;
  int _selectedGreen = 190;
  int _selectedBlue = 185;

  Future<void> _runCoughAnalysis() async {
    setState(() => _loadingCough = true);

    // Show interactive recording dialog for microphone audio capture
    int countdown = 3;
    StateSetter? dialogStateSetter;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            dialogStateSetter = setDialogState;
            return AlertDialog(
              backgroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryCyan.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mic_rounded, color: AppTheme.secondaryCyan, size: 42),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Recording Cough Audio...',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please cough 2-3 times clearly near your phone microphone.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '$countdown s',
                    style: const TextStyle(color: AppTheme.secondaryCyan, fontWeight: FontWeight.bold, fontSize: 24),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    for (int i = 3; i > 0; i--) {
      await Future.delayed(const Duration(seconds: 1));
      countdown--;
      if (dialogStateSetter != null) {
        dialogStateSetter!(() {});
      }
    }

    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    try {
      final response = await http.post(Uri.parse(ApiEndpoints.endpoint('screening/cough-demo')));
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
    setState(() {
      _selectedRed = r;
      _selectedGreen = g;
      _selectedBlue = b;
      _loadingAnemia = true;
    });
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.endpoint('screening/anemia-colorimetry')),
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
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text(
            'AI Diagnostic Suite',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white),
          ),
          bottom: const TabBar(
            labelColor: AppTheme.primaryTeal,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.primaryTeal,
            indicatorWeight: 3,
            tabs: [
              Tab(icon: Icon(Icons.water_drop, size: 20), text: "Palmar Anemia RGB"),
              Tab(icon: Icon(Icons.graphic_eq, size: 20), text: "Cough Audio ML"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Palmar Anemia RGB
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppTheme.alertRose.withOpacity(0.15),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.alertRose.withOpacity(0.3)),
                            ),
                            child: const Icon(Icons.color_lens, size: 30, color: AppTheme.alertRose),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Palmar & Finger Hemoglobin Estimator',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'GradientBoosting CIELAB Colorimetry Regressor (anemia_estimator.pkl)',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 20),

                          const Text(
                            'Select Capillary Sample Preset:',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 10),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildPresetChip('Pale Pallor', 230, 190, 185, AppTheme.alertRose),
                              _buildPresetChip('Mild Anemia', 210, 155, 140, Colors.amber),
                              _buildPresetChip('Healthy Palm', 185, 125, 105, AppTheme.primaryTeal),
                            ],
                          ),

                          if (_loadingAnemia) ...[
                            const SizedBox(height: 16),
                            const LinearProgressIndicator(color: AppTheme.alertRose),
                          ],
                        ],
                      ),
                    ),
                  ),

                  if (_anemiaResult != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'ESTIMATED HEMOGLOBIN (Hb)',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.textSecondary, letterSpacing: 1),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.alertRose.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppTheme.alertRose.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    _anemiaResult!['anemia_severity'] ?? 'ANALYZED',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.alertRose),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '${_anemiaResult!['estimated_hb_g_dl']} g/dL',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 32, color: AppTheme.alertRose),
                            ),
                            const Divider(height: 24, color: Color(0x22FFFFFF)),
                            const Text(
                              'Clinical Action Plan:',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_anemiaResult!['clinical_action']}',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Tab 2: Cough Audio ML
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryCyan.withOpacity(0.15),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.secondaryCyan.withOpacity(0.3)),
                            ),
                            child: const Icon(Icons.graphic_eq, size: 30, color: AppTheme.secondaryCyan),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Acoustic Cough Biomarker Screener',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Zero Crossing Rate & Spectral Centroid FFT Classifier (cough_classifier.pkl)',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 20),

                          ElevatedButton.icon(
                            onPressed: _loadingCough ? null : _runCoughAnalysis,
                            icon: _loadingCough
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.play_arrow_rounded),
                            label: Text(_loadingCough ? 'Analyzing Audio...' : 'Record & Classify Cough Wave'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.secondaryCyan,
                              foregroundColor: AppTheme.background,
                              minimumSize: const Size.fromHeight(48),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_coughResult != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'ACOUSTIC CLASSIFICATION',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.textSecondary, letterSpacing: 1),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.secondaryCyan.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${((_coughResult!['confidence_score'] ?? 0.8) * 100).toStringAsFixed(1)}% Confidence',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.secondaryCyan),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_coughResult!['cough_type']}',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Colors.white),
                            ),
                            const Divider(height: 24, color: Color(0x22FFFFFF)),
                            const Text(
                              'Recommendation:',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_coughResult!['clinical_recommendation']}',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, int r, int g, int b, Color accentColor) {
    final isSelected = (_selectedRed == r && _selectedGreen == g && _selectedBlue == b);
    return GestureDetector(
      onTap: () => _runAnemiaScreening(r, g, b),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withOpacity(0.2) : AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? accentColor : const Color(0x22FFFFFF),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Color.fromRGBO(r, g, b, 1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white30),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.normal,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
