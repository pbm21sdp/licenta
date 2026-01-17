import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/gemini_service.dart';
import './widgets/chat_bubble_widget.dart';
import './widgets/chat_input_widget.dart';
import './widgets/quick_suggestions_widget.dart';
import './widgets/shelter_header_widget.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final GeminiService _geminiService = GeminiService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  bool _showSuggestions = true;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() {
    setState(() {
      _messages.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'message':
            'Hello! I\'m your AI adoption assistant. How can I help you today?',
        'role': 'assistant',
        'timestamp': DateTime.now(),
        'isAI': true,
      });
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'message': text,
      'role': 'user',
      'timestamp': DateTime.now(),
      'isAI': false,
    };

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
      _showSuggestions = false;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      final chatHistory = _messages
          .where((msg) => msg['role'] != null)
          .map((msg) => {'role': msg['role'], 'message': msg['message']})
          .toList();

      final response = await _geminiService.sendMessage(text, chatHistory);

      final assistantMessage = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'message': response,
        'role': 'assistant',
        'timestamp': DateTime.now(),
        'isAI': true,
      };

      setState(() {
        _messages.add(assistantMessage);
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _messages.add({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'message': 'Sorry, I encountered an error. Please try again.',
          'role': 'assistant',
          'timestamp': DateTime.now(),
          'isAI': true,
        });
      });
    }
  }

  void _handleSuggestionTap(String suggestion) {
    _sendMessage(suggestion);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const ShelterHeaderWidget(
          shelterName: 'Adoption Assistant',
          isOnline: true,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.3,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Start a conversation',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 2.h,
                    ),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isLoading) {
                        return ChatBubbleWidget(
                          message: 'Typing...',
                          isUser: false,
                          timestamp: DateTime.now(),
                          isAI: true,
                          isLoading: true,
                        );
                      }

                      final message = _messages[index];
                      return ChatBubbleWidget(
                        message: message['message'] as String,
                        isUser: message['role'] == 'user',
                        timestamp: message['timestamp'] as DateTime,
                        isAI: message['isAI'] as bool? ?? false,
                      );
                    },
                  ),
          ),
          if (_showSuggestions && _messages.length <= 1)
            QuickSuggestionsWidget(
              suggestions: _geminiService.getQuickSuggestions(),
              onSuggestionTap: _handleSuggestionTap,
            ),
          ChatInputWidget(
            controller: _messageController,
            onSend: _sendMessage,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }
}
