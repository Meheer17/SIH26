import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/auth/auth_service.dart';
import '../../core/speech/speech_service.dart';

class MediKioskScreen extends StatefulWidget {
  const MediKioskScreen({super.key});

  @override
  State<MediKioskScreen> createState() => _MediKioskScreenState();
}

class _MediKioskScreenState extends State<MediKioskScreen> {
  final ApiClient _apiClient = ApiClient();
  final _authService = AuthService();
  final SpeechService _speechService = SpeechService();

  // Form Controllers
  final _complaintController = TextEditingController(text: 'Sore throat & headache');
  final _symptomsController = TextEditingController(text: 'cough, headache, fever');
  final _durationController = TextEditingController(text: '2 days');
  final _severityController = TextEditingController(text: '4');
  final _hpiController = TextEditingController(text: 'Started yesterday afternoon after cold drinks.');
  final _rosController = TextEditingController(text: 'No congestion, ears are normal.');
  bool _ayushMode = false;

  bool _isLoading = false;
  bool _isDictating = false;
  List<dynamic> _intakes = [];
  Map<String, dynamic>? _selectedIntake;
  Map<String, dynamic>? _ocrResult;

  @override
  void initState() {
    super.initState();
    _speechService.init();
    _fetchIntakes();
  }

  Future<void> _fetchIntakes() async {
    try {
      final res = await _apiClient.get('apps/medikiosk/intake');
      setState(() {
        _intakes = List<dynamic>.from(res);
      });
    } catch (e) {
      debugPrint('Error loading intakes: $e');
    }
  }

  void _toggleNativeDictation() {
    if (_isDictating) {
      _speechService.stopListening(onStatusChange: (listening) {
        setState(() {
          _isDictating = listening;
        });
      });
    } else {
      _speechService.listen(
        onResult: (text) {
          setState(() {
            _complaintController.text = text;
          });
        },
        onStatusChange: (listening) {
          setState(() {
            _isDictating = listening;
          });
        },
      );
    }
  }

  Future<void> _submitIntake() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final symptomsList = _symptomsController.text.split(',').map((s) => s.trim()).toList();
      final res = await _apiClient.post(
        'apps/medikiosk/intake',
        body: {
          'symptoms': symptomsList,
          'duration': _durationController.text,
          'severity_rating': int.parse(_severityController.text),
          'chief_complaint': _complaintController.text,
          'history_present_illness': _hpiController.text,
          'review_systems': _rosController.text,
          'ayush_mode': _ayushMode,
        },
      );

      _fetchIntakes();

      // Native TTS Audio Synthesis
      _speechService.speak("Clinical history submitted. Triage status is ${res['triage_level']}.");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clinical intake successfully recorded!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in.')));
    }

    final isDoctor = user.mappedRoles.contains('PHYSICIAN') || user.mappedRoles.contains('SYSTEM_ADMIN');

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(isDoctor ? 'MediKiosk Physician Terminal' : 'MediKiosk Patient Intake'),
      ),
      body: SafeArea(
        child: isDoctor ? _buildDoctorView() : _buildPatientView(),
      ),
    );
  }

  Widget _buildPatientView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: const Color(0xFF1E293B),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Symptom Intake Kiosk',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      IconButton(
                        icon: Icon(
                          _isDictating ? Icons.mic : Icons.mic_none,
                          color: _isDictating ? Colors.redAccent : Colors.lightBlueAccent,
                        ),
                        tooltip: 'Native ASR Voice Dictation',
                        onPressed: _toggleNativeDictation,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _complaintController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Chief Complaint',
                      labelStyle: const TextStyle(color: Colors.white60),
                      suffixIcon: _isDictating
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : null,
                    ),
                  ),
                  TextField(
                    controller: _symptomsController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Symptoms (comma separated)',
                      labelStyle: TextStyle(color: Colors.white60),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _durationController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Duration',
                            labelStyle: TextStyle(color: Colors.white60),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _severityController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Severity (1-10)',
                            labelStyle: TextStyle(color: Colors.white60),
                          ),
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: _hpiController,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'History of Present Illness (HPI)',
                      labelStyle: TextStyle(color: Colors.white60),
                    ),
                  ),
                  TextField(
                    controller: _rosController,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Review of Systems (ROS)',
                      labelStyle: TextStyle(color: Colors.white60),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: _ayushMode,
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _ayushMode = val;
                            });
                          }
                        },
                      ),
                      const Expanded(
                        child: Text(
                          'Include AYUSH Traditional medicine questions',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitIntake,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0EA5E9),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Submit Clinical History'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorView() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left Column: Waiting queue list
        Expanded(
          flex: 5,
          child: Container(
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: Colors.white10)),
            ),
            child: ListView.builder(
              itemCount: _intakes.length,
              itemBuilder: (context, index) {
                final item = _intakes[index];
                final isCritical = item["triage_level"] == "CRITICAL_EMERGENCY";
                return ListTile(
                  tileColor: _selectedIntake?["id"] == item["id"] ? Colors.white10 : null,
                  title: Text(
                    item["patient_name"] ?? 'Unknown Patient',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  subtitle: Text(
                    item["chief_complaint"] ?? 'No CC',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isCritical ? Colors.red.withValues(alpha: 0.2) : Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isCritical ? Colors.redAccent : Colors.white30),
                    ),
                    child: Text(
                      item["triage_level"] ?? 'ROUTINE',
                      style: TextStyle(color: isCritical ? Colors.redAccent : Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedIntake = item;
                    });
                  },
                );
              },
            ),
          ),
        ),
        // Right Column: Intake details summary
        Expanded(
          flex: 6,
          child: _selectedIntake == null
              ? const Center(
                  child: Text(
                    'Select a patient from waiting queue.',
                    style: TextStyle(color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedIntake!["patient_name"],
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Triage: ${_selectedIntake!["triage_level"]}',
                        style: const TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const Divider(color: Colors.white24, height: 20),
                      const Text(
                        'Symptoms List:',
                        style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        children: List<String>.from(_selectedIntake!["symptoms"]).map((s) {
                          return Chip(
                            backgroundColor: Colors.white12,
                            label: Text(s, style: const TextStyle(color: Colors.white, fontSize: 10)),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'AI Doctor Summary:',
                        style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _selectedIntake!["summary"],
                          style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
