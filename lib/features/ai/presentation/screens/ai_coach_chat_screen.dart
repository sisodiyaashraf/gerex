import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ai_provider.dart';
import 'offline_download_screen.dart';
import 'package:gerex/core/presentation/widgets/pastel_gradient_card.dart';
import 'package:gerex/core/presentation/widgets/gerex_scaffold.dart';
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
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);
      }
    });
  }

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
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<AIProvider>(context);

    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = keyboardHeight > 0;

    return GerexScaffold(
      appBar: AppBar(
        title: Text(
          'AI Performance Coach',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textDarkHeading,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: AppColors.accentEmeraldLight),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OfflineDownloadScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (!provider.isModelDownloaded)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OfflineDownloadScreen()),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.download_for_offline_outlined, color: theme.colorScheme.primary, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Gerex Offline AI Available',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Setup local Gemma LLM (1.2 GB) for free offline chat.',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: theme.colorScheme.primary, size: 20),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: provider.chatMessages.isEmpty
                  ? _buildEmptyState(theme)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: provider.chatMessages.length,
                      itemBuilder: (context, index) {
                        final message = provider.chatMessages[index];
                        return _buildChatBubble(theme, message);
                      },
                    ),
            ),

            // Loading spinner
            if (provider.isChatLoading)
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: PastelGradientCard(
                    type: PastelCardType.slate,
                    borderRadius: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF14181F),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Coach is thinking...',
                          style: TextStyle(
                            color: Color(0xFF14181F),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Quick Prompts — hide when keyboard is open to save space
            if (provider.chatMessages.isEmpty && !isKeyboardOpen)
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

            // Floating Input controls panel — lifts with keyboard
            AnimatedPadding(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                isKeyboardOpen ? 8 : 24,
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: theme.colorScheme.surface.withValues(alpha: 0.08),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        focusNode: _focusNode,
                        maxLines: 4,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ask Coach Gerex anything...',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
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
        child: PastelGradientCard(
          type: PastelCardType.indigo,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: const Color(0xFF14181F).withValues(alpha: 0.1),
                child: const Icon(
                  Icons.support_agent_rounded,
                  size: 40,
                  color: Color(0xFF14181F),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Meet Coach Gerex',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF14181F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ask any questions about training programs, meal plans, or posture corrections. Your virtual AI assistant is active!',
                style: TextStyle(
                  color: const Color(0xFF14181F).withValues(alpha: 0.7),
                  fontSize: 13,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _escalateQuery(String replyText) {
    final provider = Provider.of<AIProvider>(context, listen: false);
    final messages = provider.chatMessages;
    
    int replyIndex = -1;
    for (int i = 0; i < messages.length; i++) {
      if (messages[i]['text'] == replyText && messages[i]['role'] == 'model') {
        replyIndex = i;
        break;
      }
    }
    
    if (replyIndex > 0) {
      final userQuery = messages[replyIndex - 1]['text'] ?? '';
      if (userQuery.isNotEmpty) {
        provider.escalateMessageToCoach(userQuery);
        _scrollToBottom();
      }
    }
  }

  Widget _buildChatBubble(ThemeData theme, Map<String, String> message) {
    final isUser = message['role'] == 'user';
    final text = message['text'] ?? '';
    final source = message['source'] ?? 'online';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            PastelGradientCard(
              type: isUser ? PastelCardType.sky : PastelCardType.violet,
              borderRadius: 16,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                text,
                style: const TextStyle(
                  color: Color(0xFF14181F),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
            if (!isUser) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: source == 'offline'
                            ? Colors.green.withValues(alpha: 0.15)
                            : Colors.indigo.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: source == 'offline'
                              ? Colors.green.withValues(alpha: 0.3)
                              : Colors.indigo.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        source == 'offline' ? 'Offline' : 'Cloud',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: source == 'offline' ? Colors.green : Colors.indigoAccent,
                        ),
                      ),
                    ),
                    if (source == 'offline') ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _escalateQuery(text),
                        child: Row(
                          children: [
                            Icon(
                              Icons.cloud_sync_outlined,
                              size: 11,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Ask Cloud',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
