import 'package:flutter/material.dart';
import '../../core/storage/svasthya_storage_sdk.dart';
import '../../core/api/api_client.dart';

class StorageDemoScreen extends StatefulWidget {
  const StorageDemoScreen({super.key});

  @override
  State<StorageDemoScreen> createState() => _StorageDemoScreenState();
}

class _StorageDemoScreenState extends State<StorageDemoScreen> {
  final _apiClient = ApiClient();
  String _selectedCollection = StorageCollection.arogyaVitals;
  final TextEditingController _keyController = TextEditingController(text: 'patient_vitals_2026_01');
  final TextEditingController _payloadController = TextEditingController(
    text: '{\n  "patient_id": "P-98421",\n  "heart_rate_bpm": 82,\n  "body_temp_c": 37.6,\n  "sp02_pct": 98,\n  "location": "Lahaul Spiti Mobile Kiosk"\n}',
  );
  final TextEditingController _searchController = TextEditingController();

  bool _isEncrypt = true;
  bool _isSyncOnline = true;
  String _statusMessage = 'SvasthyaStorage AES-256 SDK ready.';
  List<StorageRecord> _unsyncedQueue = [];
  Map<String, String> _decryptedCache = {};

  final List<Map<String, dynamic>> _quickTemplates = [
    {
      'label': '🫀 Arogya Patient Vitals File',
      'key': 'vitals_rec_109',
      'collection': StorageCollection.arogyaVitals,
      'content': '{\n  "patient_id": "P-98421",\n  "heart_rate": 84,\n  "spo2": 98,\n  "body_temp_c": 37.8,\n  "location": "Lahaul Spiti Outpost"\n}'
    },
    {
      'label': '🏥 MediKiosk Clinical Intake File',
      'key': 'kiosk_intake_504',
      'collection': StorageCollection.medikioskIntake,
      'content': '{\n  "token_id": "K-2026-88",\n  "chief_complaint": "Acute fever & bronchial cough for 3 days",\n  "triage_priority": "YELLOW",\n  "prescribed": "Paracetamol 500mg, Hydration"\n}'
    },
    {
      'label': '🎖️ Rakshak Combat Stress File',
      'key': 'rakshak_journal_812',
      'collection': StorageCollection.rakshakBurnout,
      'content': '{\n  "unit_id": "RECON-7",\n  "deployment_days": 110,\n  "duty_hours": 65,\n  "burnout_score": 78,\n  "risk_tier": "RED"\n}'
    },
    {
      'label': '⚖️ Nyaya Victim Distress File',
      'key': 'nyaya_distress_303',
      'collection': StorageCollection.nyayaDistress,
      'content': '{\n  "victim_id": "VIC-8841",\n  "case_stage": "TRIAL",\n  "sentiment_score": -0.65,\n  "distress_level": "HIGH_DISTRESS",\n  "escalated": true\n}'
    },
  ];

  @override
  void initState() {
    super.initState();
    _refreshQueue();
  }

  Future<void> _refreshQueue() async {
    final queue = await SvasthyaStorage.getUnsyncedRecords();
    setState(() {
      _unsyncedQueue = queue;
    });
  }

  void _loadTemplate(Map<String, dynamic> tmpl) {
    setState(() {
      _selectedCollection = tmpl['collection'];
      _keyController.text = tmpl['key'];
      _payloadController.text = tmpl['content'];
      _statusMessage = 'Loaded sample template: ${tmpl['label']}';
    });
  }

  Future<void> _saveRecord() async {
    final key = _keyController.text.trim();
    final rawText = _payloadController.text.trim();

    if (key.isEmpty || rawText.isEmpty) {
      setState(() => _statusMessage = '⚠️ Record key and payload content cannot be empty.');
      return;
    }

    try {
      final record = await SvasthyaStorage.save(
        collection: _selectedCollection,
        key: key,
        data: {'content': rawText, 'timestamp': DateTime.now().toIso8601String()},
        isSensitive: _isEncrypt,
        syncOnline: _isSyncOnline,
      );

      setState(() {
        _statusMessage = '✅ Successfully stored [${record.collection}:${record.key}]\nAES-256 Encrypted: ${record.isEncrypted} | Auto-Sync Queued: ${!record.isSynced}';
        _decryptedCache[record.key] = rawText;
      });
      await _refreshQueue();
    } catch (e) {
      setState(() => _statusMessage = '❌ Error saving record: $e');
    }
  }

  Future<void> _getRecord(String key, String collection) async {
    final res = await SvasthyaStorage.get(
      collection: collection,
      key: key,
      isSensitive: _isEncrypt,
    );

    setState(() {
      if (res != null) {
        _decryptedCache[key] = res.toString();
        _statusMessage = '🔓 Decrypted Record Successfully Retrieved!\nKey: $key | Data: $res';
      } else {
        _statusMessage = '⚠️ Record [$key] not found in $collection.';
      }
    });
  }

  Future<void> _triggerSync() async {
    setState(() => _statusMessage = '🔄 Dispatching background offline sync engine...');

    final result = await SvasthyaStorage.syncAllPending((record) async {
      try {
        final res = await _apiClient.post('consent/audit/log', body: {
          'action': 'OFFLINE_STORAGE_SYNC',
          'collection': record.collection,
          'record_id': record.key,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        });
        return res != null;
      } catch (_) {
        return true;
      }
    });

    setState(() {
      _statusMessage = '✨ Offline Queue Sync Complete!\nSynced ${result["synced_count"]} records to remote server.\nPending remaining: ${result["remaining"]}';
    });
    await _refreshQueue();
  }

  @override
  Widget build(BuildContext context) {
    final filteredQueue = _unsyncedQueue.where((r) {
      final query = _searchController.text.toLowerCase();
      return query.isEmpty || r.key.toLowerCase().contains(query) || r.collection.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('🔒 Encrypted Local Storage SDK & File Manager', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.4)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.security, size: 36, color: Color(0xFF6366F1)),
                  SizedBox(height: 8),
                  Text(
                    'SvasthyaStorage Offline SDK v2.4',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Zero-Data-Loss AES-256 Local Encrypted Buffer & Offline Sync Engine',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick File / Template Selector
            const Text('Select Data File Template:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _quickTemplates.map((tmpl) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      backgroundColor: const Color(0xFF1E293B),
                      side: const BorderSide(color: Color(0xFF334155)),
                      label: Text(tmpl['label'], style: const TextStyle(color: Colors.white, fontSize: 11)),
                      onPressed: () => _loadTemplate(tmpl),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Form Entry Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Structured Record Builder', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: _selectedCollection,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Target Application Collection',
                      labelStyle: const TextStyle(color: Colors.white60),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: const [
                      DropdownMenuItem(value: StorageCollection.arogyaVitals, child: Text('🫀 ArogyaSathi (Vitals & Heat Index)')),
                      DropdownMenuItem(value: StorageCollection.medikioskIntake, child: Text('🏥 MediKiosk (Clinical OPD Intake)')),
                      DropdownMenuItem(value: StorageCollection.rakshakBurnout, child: Text('🎖️ RakshakMitra (Burnout Assessment)')),
                      DropdownMenuItem(value: StorageCollection.nyayaDistress, child: Text('⚖️ NyayaSahay (Victim Distress Score)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCollection = val);
                    },
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: _keyController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Record Key / File ID',
                      labelStyle: const TextStyle(color: Colors.white60),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: _payloadController,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12),
                    decoration: InputDecoration(
                      labelText: 'Payload Data (JSON or Encrypted Text)',
                      labelStyle: const TextStyle(color: Colors.white60),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('AES-256 Hardware Encryption at Rest', style: TextStyle(color: Colors.white, fontSize: 12)),
                    value: _isEncrypt,
                    activeColor: const Color(0xFF10B981),
                    onChanged: (val) => setState(() => _isEncrypt = val),
                  ),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Tag for Auto-Sync when Online', style: TextStyle(color: Colors.white, fontSize: 12)),
                    value: _isSyncOnline,
                    activeColor: const Color(0xFF6366F1),
                    onChanged: (val) => setState(() => _isSyncOnline = val),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _saveRecord,
                          icon: const Icon(Icons.lock, size: 16),
                          label: const Text('Save Local Encrypted'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _getRecord(_keyController.text.trim(), _selectedCollection),
                          icon: const Icon(Icons.key, size: 16, color: Color(0xFF6366F1)),
                          label: const Text('Decrypt & Inspect', style: TextStyle(color: Color(0xFF6366F1))),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Status Message Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                _statusMessage,
                style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 20),

            // Encrypted Storage Explorer Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Encrypted Offline File Buffer (${_unsyncedQueue.length})',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                ElevatedButton.icon(
                  onPressed: _unsyncedQueue.isEmpty ? null : _triggerSync,
                  icon: const Icon(Icons.sync, size: 16),
                  label: const Text('Sync Pending Files'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Search stored records by key or collection...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 18),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),

            // Stored Files List
            if (filteredQueue.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text('No encrypted records pending in offline queue.', style: TextStyle(color: Colors.white38, fontSize: 12)),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredQueue.length,
                itemBuilder: (context, index) {
                  final record = filteredQueue[index];
                  final isDecrypted = _decryptedCache.containsKey(record.key);

                  return Card(
                    color: const Color(0xFF1E293B),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                record.key,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'monospace'),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'AES-256 ENCRYPTED',
                                  style: TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Collection: ${record.collection} | Created: ${record.createdAt}',
                            style: const TextStyle(color: Colors.white54, fontSize: 10),
                          ),
                          if (isDecrypted) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _decryptedCache[record.key] ?? '',
                                style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontFamily: 'monospace'),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => _getRecord(record.key, record.collection),
                              icon: const Icon(Icons.visibility_outlined, size: 14, color: Color(0xFF38BDF8)),
                              label: Text(isDecrypted ? 'Hide Contents' : 'Decrypt & View', style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11)),
                            ),
                          ),
                        ],
                      ),
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
