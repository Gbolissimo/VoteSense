import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../utils/globals.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];

  bool _isLoading = false;
  bool _isConfigLoading = true;

  String? _fetchedApiKey;
  String? _fetchedApiVersion;
  String? _fetchedModel;

  final String _sessionId = globalUid;
  LegalLanguage _selectedLanguage = LegalLanguage.english;

  // Updated to primary green and light mode backgrounds
  static const Color primaryColor = Color(0xFF22C55E);
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color cardBackground = Colors.white;

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
    _loadConversationHistory();
  }

  Future<void> _loadConfiguration() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('AI').doc('api').get();
      if (doc.exists) {
        setState(() {
          _fetchedApiKey = doc['key'];
          _fetchedApiVersion = doc['version'] ?? 'v1beta';
          _fetchedModel = doc['model'] ?? 'gemini-2.5-flash';
          _isConfigLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Config Error: $e");
    }
  }

  Future<void> _loadConversationHistory() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('conversations')
        .doc(_sessionId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .get();

    final docs = snapshot.docs.reversed.toList();

    setState(() {
      _messages = docs.map((doc) => ChatMessage(
        text: doc['text'],
        isUser: doc['isUser'],
        timestamp: (doc['timestamp'] as Timestamp).toDate(),
      )).toList();
    });

    if (_messages.isEmpty) {
      _addInitialGreeting();
    } else {
      _scrollToBottom();
    }
  }

  Future<void> _saveMessageToFirestore(ChatMessage msg) async {
    await FirebaseFirestore.instance
        .collection('conversations')
        .doc(_sessionId)
        .collection('messages')
        .add({
      'text': msg.text,
      'isUser': msg.isUser,
      'timestamp': msg.timestamp,
    });
  }

  void _addInitialGreeting() {
    final msg = ChatMessage(
      text: _getGreetingForLanguage(_selectedLanguage),
      isUser: false,
      timestamp: DateTime.now(),
    );
    setState(() => _messages.add(msg));
    _saveMessageToFirestore(msg);
    _scrollToBottom();
  }

  Future<void> _sendMessage([String? quickPrompt]) async {
    final text = quickPrompt ?? _messageController.text.trim();
    if (text.isEmpty || _isLoading || _fetchedApiKey == null) return;

    if (quickPrompt == null) _messageController.clear();

    final userMsg = ChatMessage(text: text, isUser: true, timestamp: DateTime.now());
    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
    });
    _saveMessageToFirestore(userMsg);
    _scrollToBottom();

    try {
      final responseText = await _callGeminiApi(text);

      final cleanText = responseText.replaceAll('*', '');

      if (mounted) {
        final aiMsg = ChatMessage(text: cleanText, isUser: false, timestamp: DateTime.now());
        setState(() {
          _messages.add(aiMsg);
          _isLoading = false;
        });
        _saveMessageToFirestore(aiMsg);
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<String> _callGeminiApi(String userPrompt) async {
    final String systemInstruction = 'You are VoteSense AI, an expert election and civic companion for Nigeria. Respond strictly in ${_selectedLanguage.displayName}. Keep your answers short and clear. The name of the user is $globalFirstName';

    final url = Uri.parse('https://generativelanguage.googleapis.com/$_fetchedApiVersion/models/$_fetchedModel:generateContent?key=$_fetchedApiKey');

    final conversationHistory = _messages.map((m) => {
      "role": m.isUser ? "user" : "model",
      "parts": [{"text": m.text}]
    }).toList();

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "system_instruction": {"parts": [{"text": systemInstruction}]},
        "contents": conversationHistory,
        "generationConfig": {"temperature": 0.4, "maxOutputTokens": 1024}
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? 'No response.';
    } else {
      throw Exception('API Error');
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

  String _getGreetingForLanguage(LegalLanguage lang) {
    switch (lang) {
      case LegalLanguage.yoruba: return 'Ẹ n\'lẹ́ o! Emi ni Aṣoju VoteSense AI.';
      case LegalLanguage.igbo: return 'Nnọọ! Abụ m VoteSense AI.';
      case LegalLanguage.hausa: return 'Sannu da zuwa! Ni ne VoteSense AI.';
      case LegalLanguage.pidgin: return 'How body! I be VoteSense AI.';
      case LegalLanguage.english: return 'Hello! I am VoteSense AI. Ask me any election or civic question.';
    }
  }

  void _onLanguageChanged(LegalLanguage? newLanguage) {
    if (newLanguage != null && newLanguage != _selectedLanguage) {
      setState(() => _selectedLanguage = newLanguage);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isConfigLoading) {
      return const Scaffold(backgroundColor: lightBackground, body: Center(child: CircularProgressIndicator(color: primaryColor)));
    }

    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        backgroundColor: cardBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1E293B),
            size: 18,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('VoteSense AI', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: lightBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
            ),
            child: DropdownButton<LegalLanguage>(
              value: _selectedLanguage,
              dropdownColor: cardBackground,
              underline: const SizedBox(),
              icon: const Icon(Icons.translate, color: primaryColor, size: 18),
              onChanged: _onLanguageChanged,
              items: LegalLanguage.values.map((lang) => DropdownMenuItem(value: lang, child: Text(lang.displayName, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.w500)))).toList(),
            ),
          ),
          const SizedBox(width: 15),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
            ),
          ),
          if (_isLoading) const Padding(padding: EdgeInsets.all(8.0), child: LinearProgressIndicator(color: primaryColor)),
          _buildInputArea(),
          SizedBox(height: 15,)
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: message.isUser ? primaryColor : cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
          border: message.isUser ? null : Border.all(color: Colors.black.withValues(alpha: 0.05)),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser ? Colors.white : const Color(0xFF1E293B),
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      decoration: BoxDecoration(
        color: cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: lightBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Color(0xFF1E293B)),
                decoration: const InputDecoration(
                  hintText: 'Ask an election or civic question...',
                  hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              onPressed: () => _sendMessage(),
            ),
          ),
        ],
      ),
    );
  }
}

enum LegalLanguage {
  english('English'), yoruba('Yoruba'), igbo('Igbo'), hausa('Hausa'), pidgin('Pidgin');
  final String displayName;
  const LegalLanguage(this.displayName);
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  ChatMessage({required this.text, required this.isUser, required this.timestamp});
}