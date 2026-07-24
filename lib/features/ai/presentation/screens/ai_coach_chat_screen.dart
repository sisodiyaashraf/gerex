import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ai_provider.dart';
import 'package:gerex/core/presentation/widgets/liquid_background.dart';
import 'package:gerex/core/presentation/widgets/glass_container.dart';
import 'package:gerex/core/theme/app_theme.dart';
import 'package:gerex/core/validation/validators.dart';

class AICoachChatScreen extends StatefulWidget {
  const AICoachChatScreen({super.key});

  @override
  State<AICoachChatScreen> createState() => _AICoachChatScreenState();
}

class _AICoachChatScreenState extends State<AICoachChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _quickPrompts = [
    'How do I fix my squat form?',
    'What should I eat post-workout?',
    'Suggest a dynamic warmup routine',
  ];

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
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<AIProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coach Gerex (AI)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () => provider.clearChat(),
          ),
        ],
      ),
      body: LiquidBackground(
        child: Column(
          children: [
            // Chat history log bubbles
            Expanded(
              child: provider.chatMessages.isEmpty
                  ? _buildEmptyState(theme)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: provider.chatMessages.length,
                      itemBuilder: (context, index) {
                        final message = provider.chatMessages[index];
                        final isUser = message['role'] == 'user';
                        return _buildChatBubble(theme, isUser, message['text'] ?? '');
                      },
                    ),
            ),

            // Loading spinner
            if (provider.isChatLoading)
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: GlassContainer(
                    borderRadius: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Coach is thinking...',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Quick Prompts list
            if (provider.chatMessages.isEmpty)
              SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _quickPrompts.length,
                  itemBuilder: (context, index) {
                    final prompt = _quickPrompts[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ActionChip(
                        label: Text(prompt),
                        onPressed: () {
                          provider.sendMessageToCoach(prompt);
                          _scrollToBottom();
                        },
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),

            // Floating Input controls panel
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: GlassContainer(
                padding: const EdgeInsets.all(8),
                borderRadius: 24,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Ask Coach Gerex anything...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          isDense: true,
                        ),
                        onSubmitted: (val) {
                          final error = Validators.validateAiChatInput(val);
                          if (error != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error)),
                            );
                            return;
                          }
                          provider.sendMessageToCoach(val.trim());
                          _messageController.clear();
                          _scrollToBottom();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.primary,
                      child: IconButton(
                        icon: Icon(Icons.send, color: theme.colorScheme.onPrimary),
                        onPressed: () {
                          final text = _messageController.text;
                          final error = Validators.validateAiChatInput(text);
                          if (error != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error)),
                            );
                            return;
                          }
                          provider.sendMessageToCoach(text.trim());
                          _messageController.clear();
                          _scrollToBottom();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: GlassContainer(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                child: Icon(
                  Icons.support_agent_rounded,
                  size: 40,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Meet Coach Gerex',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ask any questions about training programs, meal plans, or posture corrections. Your virtual AI assistant is active!',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatBubble(ThemeData theme, bool isUser, String text) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: GlassContainer(
          borderRadius: 16,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          borderGradient: isUser ? GerexGradients.primaryCTA : null,
          color: isUser
              ? theme.colorScheme.primary.withValues(alpha: 0.15)
              : theme.colorScheme.surface.withValues(alpha: 0.1),
          child: Text(
            text,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}
