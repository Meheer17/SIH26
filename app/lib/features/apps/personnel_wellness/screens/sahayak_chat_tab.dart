import 'package:flutter/material.dart';
import '../services/raksha_setu_service.dart';

class SahayakChatTab extends StatefulWidget {
  final VoidCallback onTriggerSos;

  const SahayakChatTab({super.key, required this.onTriggerSos});

  @override
  State<SahayakChatTab> createState() => _SahayakChatTabState();
}

class _SahayakChatTabState extends State<SahayakChatTab> {
  final RakshaSetuService _service = RakshaSetuService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isSending = false;
  String _selectedLanguage = 'hi'; // 'hi' or 'en'
  bool _crisisDetected = false;

  final List<Map<String, dynamic>> _messages = [
    {
      'isUser': false,
      'text': 'जय हिन्द, साथी! मैं "सहायक" (Sahayak) हूँ — आपका गोपनीय कल्याण साथी। ड्यूटी का तनाव, नींद की समस्या, या घर-परिवार की चिंता, आप मुझसे बेझिझक साझा कर सकते हैं। आज मैं आपकी क्या सहायता करूँ?',
      'time': 'Just now',
      'isCrisis': false,
    }
  ];

  final List<String> _quickPrompts = [
    'ड्यूटी के बाद तनाव महसूस हो रहा है',
    'रात के पहरे के बाद नींद नहीं आ रही',
    '4-4-4-4 Box Breathing अभ्यास कराएं',
    'Feeling isolated in high-altitude post',
    'Missing family and children',
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await _service.fetchChatHistory();
      if (history.isNotEmpty && mounted) {
        setState(() {
          _messages.clear();
          for (var h in history) {
            _messages.add({
              'isUser': true,
              'text': h['user_message'] ?? '',
              'time': 'Previous',
              'isCrisis': false,
            });
            _messages.add({
              'isUser': false,
              'text': h['bot_reply'] ?? '',
              'time': 'Previous',
              'isCrisis': h['is_crisis_flagged'] == true,
            });
          }
        });
        _scrollToBottom();
      }
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? customText]) async {
    final text = customText ?? _messageController.text.trim();
    if (text.isEmpty) return;

    if (customText == null) {
      _messageController.clear();
    }

    setState(() {
      _messages.add({
        'isUser': true,
        'text': text,
        'time': 'Now',
        'isCrisis': false,
      });
      _isSending = true;
    });
    _scrollToBottom();

    try {
      final res = await _service.sendChatMessage(text, language: _selectedLanguage);
      final reply = res['reply'] as String? ?? 'I hear you, comrade.';
      final isCrisis = res['is_crisis'] == true;

      if (mounted) {
        setState(() {
          _isSending = false;
          if (isCrisis) _crisisDetected = true;
          _messages.add({
            'isUser': false,
            'text': reply,
            'time': 'Now',
            'isCrisis': isCrisis,
          });
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
          _messages.add({
            'isUser': false,
            'text': 'Network error connecting to Sahayak. Please verify connection.',
            'time': 'Now',
            'isCrisis': false,
          });
        });
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF7C3AED).withOpacity(0.12),
              child: const Icon(Icons.smart_toy, color: Color(0xFF7C3AED), size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Sahayak AI • सहायक',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                Text(
                  'Confidential Armed Forces Welfare Assistant',
                  style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: _selectedLanguage,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'hi', child: Text('🇮🇳 हिंदी', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 'en', child: Text('🇬🇧 English', style: TextStyle(fontSize: 12))),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedLanguage = val);
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Emergency Crisis Red-Flag Banner
          if (_crisisDetected)
            Container(
              padding: const EdgeInsets.all(12),
              color: const Color(0xFFFEF2F2),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '24x7 Armed Forces Mental Health Helpline',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                        Text(
                          'Dial Tele-MANAS: 14416 / 1800-891-4416 (Free & Confidential)',
                          style: TextStyle(fontSize: 11, color: Color(0xFF991B1B)),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: widget.onTriggerSos,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    child: const Text('SOS CALL'),
                  ),
                ],
              ),
            ),

          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['isUser'] as bool;
                final text = msg['text'] as String;
                final isCrisis = msg['isCrisis'] as bool;

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUser
                          ? const Color(0xFF0284C7)
                          : (isCrisis ? const Color(0xFFFEE2E2) : Colors.white),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                        bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                      ),
                      border: isUser ? null : Border.all(color: isCrisis ? Colors.red.shade300 : const Color(0xFFE2E8F0)),
                      boxShadow: const [
                        BoxShadow(color: Color(0x060F172A), blurRadius: 6, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isUser)
                          Row(
                            children: [
                              Icon(
                                isCrisis ? Icons.crisis_alert : Icons.support_agent_rounded,
                                size: 14,
                                color: isCrisis ? Colors.red : const Color(0xFF7C3AED),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isCrisis ? 'Emergency Intervention' : 'Sahayak Welfare AI',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isCrisis ? Colors.red : const Color(0xFF7C3AED),
                                ),
                              ),
                            ],
                          ),
                        if (!isUser) const SizedBox(height: 6),
                        Text(
                          text,
                          style: TextStyle(
                            fontSize: 13,
                            color: isUser ? Colors.white : const Color(0xFF1E293B),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          if (_isSending)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: const [
                  SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF7C3AED))),
                  SizedBox(width: 8),
                  Text('Sahayak is responding with tactical guidance...', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ],
              ),
            ),

          // Quick Suggestion Chips
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _quickPrompts.length,
              itemBuilder: (context, index) {
                final p = _quickPrompts[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(p, style: const TextStyle(fontSize: 11, color: Color(0xFF334155))),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    onPressed: () => _sendMessage(p),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: _selectedLanguage == 'hi' ? 'अपनी बात यहाँ लिखें...' : 'Type confidential message...',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.mic, color: Color(0xFF64748B)),
                  onPressed: () {
                    _messageController.text = 'ड्यूटी के बाद बहुत शारीरिक थकान और नींद की कमी लग रही है।';
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: Color(0xFF0284C7)),
                  onPressed: _isSending ? null : () => _sendMessage(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
