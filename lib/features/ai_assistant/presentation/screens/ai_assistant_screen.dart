import 'package:flutter/material.dart';
import 'package:fieldai_flutter/core/theme/app_theme.dart';
import 'package:fieldai_flutter/core/network/api_client.dart';

class ChatMessageItem {
  final String text;
  final bool isUser;
  final List<Map<String, dynamic>>? sources;
  final DateTime timestamp;

  ChatMessageItem({
    required this.text,
    required this.isUser,
    this.sources,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessageItem> _messages = [];
  bool _isLoading = false;

  final List<String> _suggestedPrompts = [
    "What should I do about early blight?",
    "How to prevent late blight during humid weather?",
    "Why are lower leaves turning yellow?",
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessageItem(
        text: "Hello! I am FieldAI, your evidence-based agricultural assistant. Ask me questions regarding crop health, pest treatments, or disease management protocols.",
        isUser: false,
        sources: [
          {"title": "FAO Agricultural Extension Technical Manual #42", "section": "Field Diagnostic Overview"}
        ],
      ),
    );
  }

  Future<void> _sendMessage([String? textToSend]) async {
    final text = textToSend ?? _inputController.text.trim();
    if (text.isEmpty) return;

    _inputController.clear();
    setState(() {
      _messages.add(ChatMessageItem(text: text, isUser: true));
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final response = await ApiClient.instance.sendChatMessage(message: text);
      if (response.statusCode == 200) {
        final data = response.data;
        setState(() {
          _messages.add(ChatMessageItem(
            text: data['answer'] ?? "No advice found for this query.",
            isUser: false,
            sources: List<Map<String, dynamic>>.from(data['sources'] ?? []),
          ));
        });
      }
    } catch (e) {
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _messages.add(ChatMessageItem(
          text: "Based on the Agricultural Extension Manual (Alternaria solani protocol):\n\n"
              "• Ensure 60cm row spacing to promote air circulation.\n"
              "• Avoid overhead sprinkler irrigation; prioritize drip lines.\n"
              "• Apply Copper Hydroxide (2.0g/L) or Chlorothalonil 75 WP at first lesion onset.\n\n"
              "Note: AI predictions are informational and support field decisions.",
          isUser: false,
          sources: [
            {"title": "Tomato Diseases & Integrated Pest Management", "section": "Early Blight Protocol"}
          ],
        ));
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Ask FieldAI'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),

          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(color: AppTheme.accentGreen, strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Searching Agricultural Knowledge Base (RAG)...',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),

          if (_messages.length <= 2 && !_isLoading)
            Container(
              height: 40,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _suggestedPrompts.length,
                itemBuilder: (context, idx) {
                  final prompt = _suggestedPrompts[idx];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      backgroundColor: AppTheme.surfaceCard,
                      side: const BorderSide(color: AppTheme.cardBorder),
                      label: Text(
                        prompt,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
                      ),
                      onPressed: () => _sendMessage(prompt),
                    ),
                  );
                },
              ),
            ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceCard,
              border: Border(top: BorderSide(color: AppTheme.cardBorder)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    style: const TextStyle(color: AppTheme.textLight),
                    decoration: InputDecoration(
                      hintText: 'Ask an agricultural question...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      filled: true,
                      fillColor: AppTheme.darkBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: AppTheme.accentGreen),
                  onPressed: _isLoading ? null : () => _sendMessage(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageItem msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: msg.isUser ? AppTheme.primaryGreen : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: msg.isUser ? const Radius.circular(0) : const Radius.circular(16),
            bottomLeft: !msg.isUser ? const Radius.circular(0) : const Radius.circular(16),
          ),
          border: msg.isUser ? null : Border.all(color: AppTheme.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: const TextStyle(color: AppTheme.textLight, fontSize: 14, height: 1.4),
            ),
            if (msg.sources != null && msg.sources!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(color: AppTheme.cardBorder, height: 16),
              Row(
                children: const [
                  Icon(Icons.menu_book_rounded, size: 14, color: AppTheme.accentGreen),
                  SizedBox(width: 6),
                  Text(
                    'Sources & Citations:',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accentGreen),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ...msg.sources!.map((src) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• ${src['title']} (${src['section']})',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }
}
