import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AiAgentInfo {
  final String agentId;
  final String name;
  final String badge;
  final String description;
  final Color color;

  const AiAgentInfo({
    required this.agentId,
    required this.name,
    required this.badge,
    required this.description,
    required this.color,
  });
}

class ChatMessageModel {
  final String id;
  final String role;
  final String content;
  final String? engine;
  final List<dynamic>? toolCalls;
  final String timestamp;

  ChatMessageModel({
    required this.id,
    required this.role,
    required this.content,
    this.engine,
    this.toolCalls,
    required this.timestamp,
  });
}

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<AiAgentInfo> _agents = const [
    AiAgentInfo(
      agentId: 'arogya_sathi_agent',
      name: 'ArogyaSathi AI',
      badge: '🫀 ArogyaSathi',
      description: 'Continuous health monitoring, heat stress, & NDMA advisories.',
      color: Color(0xFF10B981),
    ),
    AiAgentInfo(
      agentId: 'medikiosk_agent',
      name: 'MediKiosk AI',
      badge: '🏥 MediKiosk',
      description: 'Clinical OPD intake, SOCRATES history, & red-flag triage.',
      color: Color(0xFF0EA5E9),
    ),
    AiAgentInfo(
      agentId: 'rakshak_mitra_agent',
      name: 'RakshakMitra AI',
      badge: '🎖️ RakshakMitra',
      description: 'Armed forces burnout prediction & welfare recommendations.',
      color: Color(0xFFF59E0B),
    ),
    AiAgentInfo(
      agentId: 'nyaya_sahay_agent',
      name: 'NyayaSahay AI',
      badge: '⚖️ NyayaSahay',
      description: 'SC/ST victim proactive outreach & legal stage support.',
      color: Color(0xFFA855F7),
    ),
    AiAgentInfo(
      agentId: 'general_assistant_agent',
      name: 'General Assistant',
      badge: '🤖 General AI',
      description: 'General health guidance & platform assistance.',
      color: Color(0xFF6366F1),
    ),
  ];

  late AiAgentInfo _selectedAgent;
  final Map<String, List<ChatMessageModel>> _messagesMap = {};
  bool _isLoading = false;

  final Map<String, List<String>> _suggestionsMap = {
    'arogya_sathi_agent': [
      'Heatstroke prevention during heatwave?',
      'Analyze heat stress: 38°C body temp, 42°C ambient.',
    ],
    'medikiosk_agent': [
      'Chest pain and breathlessness for 1 hour. Triage me.',
      'Prepare OPD clinical summary for doctor.',
    ],
    'rakshak_mitra_agent': [
      'Predict burnout risk for 90 days field deployment.',
      'Suggest commander welfare actions.',
    ],
    'nyaya_sahay_agent': [
      'Assess victim distress score in chargesheet stage.',
      'Trigger legal aid escalation dispatch.',
    ],
    'general_assistant_agent': [
      'How does SvasthyaSetu platform work?',
      'Preventive health tips for seasonal flu.',
    ],
  };

  @override
  void initState() {
    super.initState();
    _selectedAgent = _agents[0];
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

  Future<void> _sendMessage([String? textOverride]) async {
    final text = textOverride ?? _inputController.text.trim();
    if (text.isEmpty || _isLoading) return;

    final userMsg = ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      content: text,
      timestamp: TimeOfDay.now().format(context),
    );

    setState(() {
      _messagesMap.putIfAbsent(_selectedAgent.agentId, () => []);
      _messagesMap[_selectedAgent.agentId]!.add(userMsg);
      if (textOverride == null) _inputController.clear();
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final currentList = _messagesMap[_selectedAgent.agentId] ?? [];
      final payloadMessages = currentList.map((m) => {'role': m.role, 'content': m.content}).toList();

      final url = Uri.parse('http://localhost:8000/api/v1/ai/chat');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'agent_id': _selectedAgent.agentId,
          'messages': payloadMessages,
          'context': {
            'env_temp_c': 38.0,
            'humidity_percent': 65.0,
            'body_temp_c': 37.2,
            'duty_hours_per_week': 55.0,
            'case_stage': 'chargesheet',
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final assistantMsg = ChatMessageModel(
          id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
          role: 'assistant',
          content: data['content'] ?? '',
          engine: data['engine'],
          toolCalls: data['tool_calls'],
          timestamp: TimeOfDay.now().format(context),
        );

        setState(() {
          _messagesMap[_selectedAgent.agentId]!.add(assistantMsg);
        });
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      final fallbackMsg = ChatMessageModel(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        role: 'assistant',
        content: '[${_selectedAgent.name}] Operating in smart offline fallback mode. Received: "$text".',
        engine: 'fallback_offline',
        timestamp: TimeOfDay.now().format(context),
      );

      setState(() {
        _messagesMap[_selectedAgent.agentId]!.add(fallbackMsg);
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeMessages = _messagesMap[_selectedAgent.agentId] ?? [];
    final suggestions = _suggestionsMap[_selectedAgent.agentId] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _selectedAgent.color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.psychology_outlined, color: _selectedAgent.color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedAgent.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const Text(
                    'Bedrock Mantle AI Hub',
                    style: TextStyle(fontSize: 11, color: Colors.white54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Agent Selector Tab Bar
          Container(
            height: 54,
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: const Color(0xFF1E293B).withValues(alpha: 0.5),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _agents.length,
              itemBuilder: (context, index) {
                final agent = _agents[index];
                final isSelected = agent.agentId == _selectedAgent.agentId;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedAgent = agent;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? agent.color.withValues(alpha: 0.25) : const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? agent.color : Colors.white12,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        agent.badge,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? agent.color : Colors.white70,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Message Timeline
          Expanded(
            child: activeMessages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_bubble_outline, size: 48, color: Colors.white24),
                        const SizedBox(height: 12),
                        Text(
                          'Ask ${_selectedAgent.name}',
                          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            _selectedAgent.description,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: activeMessages.length,
                    itemBuilder: (context, index) {
                      final msg = activeMessages[index];
                      final isUser = msg.role == 'user';

                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.82,
                          ),
                          decoration: BoxDecoration(
                            color: isUser ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(18),
                              topRight: const Radius.circular(18),
                              bottomLeft: isUser ? const Radius.circular(18) : Radius.zero,
                              bottomRight: isUser ? Radius.zero : const Radius.circular(18),
                            ),
                            border: isUser ? null : Border.all(color: Colors.white12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg.content,
                                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                              ),
                              if (msg.toolCalls != null && msg.toolCalls!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F172A),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.white10),
                                  ),
                                  child: Text(
                                    '🛠️ Tool Output:\n${jsonEncode(msg.toolCalls)}',
                                    style: const TextStyle(color: Color(0xFF34D399), fontSize: 11, fontFamily: 'monospace'),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                msg.timestamp,
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1)),
              ),
            ),

          // Suggestion Chips
          if (suggestions.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _sendMessage(suggestions[index]),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(
                        suggestions[index],
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ),
                  );
                },
              ),
            ),

          // Bottom Input Bar
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF1E293B),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Ask ${_selectedAgent.name}...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isLoading ? null : () => _sendMessage(),
                  icon: const Icon(Icons.send_rounded, color: Color(0xFF6366F1)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
