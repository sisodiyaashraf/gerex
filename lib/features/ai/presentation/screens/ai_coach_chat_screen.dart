import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/ai_provider.dart';
import 'offline_download_screen.dart';
import 'package:gerex/core/presentation/widgets/pastel_gradient_card.dart';
import 'package:gerex/core/presentation/widgets/gerex_scaffold.dart';
import 'package:gerex/core/theme/app_theme.dart';
import 'package:gerex/core/validation/validators.dart';
import 'package:gerex/core/di/injection_container.dart' as di;
import 'package:gerex/core/services/voice_coach_service.dart';

class AICoachChatScreen extends StatefulWidget {
  const AICoachChatScreen({super.key});

  @override
  State<AICoachChatScreen> createState() => _AICoachChatScreenState();
}

class _AICoachChatScreenState extends State<AICoachChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _showScrollFAB = false;
  bool _isSpeaking = false;
  int? _speakingMessageIndex;
  bool _isDictating = false;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  final List<String> _quickPrompts = [
    'Suggest a workout',
    'Check my BMI',
    "What's my streak?",
    'Recommend a meal',
    'Form correction tips',
    'Post-workout recovery',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scrollController.addListener(_onScrollChanged);
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);
      }
    });
  }

  void _onScrollChanged() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    final isScrolledUp = (maxScroll - currentScroll) > 160;

    if (isScrolledUp != _showScrollFAB) {
      setState(() {
        _showScrollFAB = isScrolledUp;
      });
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
  void dispose() {
    _pulseController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _speakResponse(String text, int messageIndex) async {
    try {
      final voiceCoach = di.sl<VoiceCoachService>();
      if (_isSpeaking && _speakingMessageIndex == messageIndex) {
        await voiceCoach.stop();
        setState(() {
          _isSpeaking = false;
          _speakingMessageIndex = null;
        });
        return;
      }

      setState(() {
        _isSpeaking = true;
        _speakingMessageIndex = messageIndex;
      });

      await voiceCoach.speak(text);

      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _speakingMessageIndex = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _speakingMessageIndex = null;
        });
      }
    }
  }

  void _toggleDictation() {
    setState(() {
      _isDictating = !_isDictating;
    });

    if (_isDictating) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Listening... Dictate your message to Coach Gerex 🎙️'),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Simulate dictation insert sample prompt if empty
      if (_messageController.text.isEmpty) {
        _messageController.text =
            'Give me a 15-minute quick core workout routine';
      }
    }
  }

  void _confirmClearChat(AIProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151729),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Clear Conversation?',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to clear your current conversation history with Coach Gerex?',
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              provider.clearChat();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Conversation history cleared.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Clear',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<AIProvider>(context);

    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = keyboardHeight > 0;
    final isDark = theme.brightness == Brightness.dark;

    final headerTextColor = isDark ? Colors.white : AppColors.textLightHeading;

    return GerexScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'AI Performance Coach',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: headerTextColor,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.download_rounded,
              color: AppColors.accentEmeraldLight,
            ),
            tooltip: 'Offline Model Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OfflineDownloadScreen(),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: headerTextColor),
            color: const Color(0xFF151729),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onSelected: (val) {
              if (val == 'clear') {
                _confirmClearChat(provider);
              } else if (val == 'offline') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OfflineDownloadScreen(),
                  ),
                );
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'offline',
                child: Row(
                  children: [
                    const Icon(
                      Icons.download_for_offline_outlined,
                      color: AppColors.accentEmeraldLight,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Offline Models',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Clear Conversation',
                      style: GoogleFonts.inter(
                        color: Colors.redAccent,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: _showScrollFAB
          ? Padding(
              padding: const EdgeInsets.only(bottom: 72.0),
              child: FloatingActionButton.small(
                onPressed: _scrollToBottom,
                backgroundColor: AppColors.accentEmeraldDeep,
                child: const Icon(
                  Icons.arrow_downward_rounded,
                  color: Colors.white,
                ),
              ),
            )
          : null,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (!provider.isModelDownloaded)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OfflineDownloadScreen(),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0x2610B981)
                        : const Color(0x1F059669),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? const Color(0x4010B981)
                          : const Color(0x40059669),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.download_for_offline_outlined,
                        color: isDark
                            ? const Color(0xFF34D399)
                            : const Color(0xFF047857),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gerex Offline AI Available',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isDark
                                    ? const Color(0xFF34D399)
                                    : const Color(0xFF047857),
                              ),
                            ),
                            Text(
                              'Setup local Gemma LLM (1.2 GB) for free offline chat.',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: isDark
                            ? const Color(0xFF34D399)
                            : const Color(0xFF047857),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

            // Messages ListView
            Expanded(
              child: provider.chatMessages.isEmpty
                  ? _buildEmptyState(theme, isDark)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: provider.chatMessages.length,
                      itemBuilder: (context, index) {
                        final message = provider.chatMessages[index];
                        return _buildChatBubble(
                          theme,
                          message,
                          index,
                          provider,
                          isDark,
                        );
                      },
                    ),
            ),

            // Thinking / Typing Indicator with Robot Mascot
            if (provider.isChatLoading)
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildRobotAvatar(),
                      const SizedBox(width: 8),
                      FadeTransition(
                        opacity: _pulseAnimation,
                        child: const PastelGradientCard(
                          type: PastelCardType.slate,
                          borderRadius: 16,
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Coach Gerex is typing...',
                                style: TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Quick Prompt Suggestions Row — hides when keyboard is open
            if (!isKeyboardOpen)
              SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _quickPrompts.length,
                  itemBuilder: (context, index) {
                    final prompt = _quickPrompts[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ActionChip(
                        elevation: 0,
                        backgroundColor: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFE2E8F0),
                        side: BorderSide(
                          color: isDark
                              ? Colors.white10
                              : const Color(0xFFCBD5E1),
                        ),
                        label: Text(
                          prompt,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        onPressed: () {
                          provider.sendMessageToCoach(prompt);
                          _scrollToBottom();
                        },
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 6),

            // Floating Input controls panel — lifts with keyboard
            AnimatedPadding(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              padding: EdgeInsets.fromLTRB(16, 4, 16, isKeyboardOpen ? 8 : 20),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  children: [
                    // Mic dictation button
                    IconButton(
                      icon: Icon(
                        _isDictating ? Icons.mic : Icons.mic_none_rounded,
                        color: _isDictating
                            ? Colors.redAccent
                            : (isDark
                                  ? Colors.white70
                                  : const Color(0xFF475569)),
                        size: 22,
                      ),
                      tooltip: 'Voice Input',
                      onPressed: _toggleDictation,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        focusNode: _focusNode,
                        maxLines: 4,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        style: GoogleFonts.inter(
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ask Coach Gerex anything...',
                          hintStyle: GoogleFonts.inter(
                            color: isDark
                                ? const Color(0x99F1F5F9)
                                : const Color(0x99475569),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          isDense: true,
                        ),
                        onSubmitted: (val) {
                          final error = Validators.validateAiChatInput(val);
                          if (error != null) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text(error)));
                            return;
                          }
                          provider.sendMessageToCoach(val.trim());
                          _messageController.clear();
                          _scrollToBottom();
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.accentEmeraldDeep,
                      child: IconButton(
                        icon: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        onPressed: () {
                          final text = _messageController.text;
                          final error = Validators.validateAiChatInput(text);
                          if (error != null) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text(error)));
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

  Widget _buildRobotAvatar() {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF1E293B),
        border: Border.all(color: AppColors.accentEmeraldLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentEmeraldLight.withValues(alpha: 0.2),
            blurRadius: 6,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/robot_mascot/gerex_robot_idle.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const FaIcon(
            FontAwesomeIcons.robot,
            size: 18,
            color: AppColors.accentEmeraldLight,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: PastelGradientCard(
          type: PastelCardType.indigo,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0F172A).withValues(alpha: 0.15),
                  border: Border.all(
                    color: AppColors.accentEmeraldLight.withValues(alpha: 0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentEmeraldLight.withValues(alpha: 0.2),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Image.asset(
                  'assets/images/robot_mascot/ai_face_detector.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => _buildRobotAvatar(),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Meet Coach Gerex',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ask any questions about workout routines, meal plans, BMI, or form correction. Your Gerex AI assistant is active!',
                style: GoogleFonts.inter(
                  color: const Color(0xFF334155),
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

  Widget _buildChatBubble(
    ThemeData theme,
    Map<String, String> message,
    int index,
    AIProvider provider,
    bool isDark,
  ) {
    final isUser = message['role'] == 'user';
    final text = message['text'] ?? '';
    final source = message['source'] ?? 'online';
    final feedback = message['feedback'];
    final isError =
        message['isError'] == 'true' || text.contains('Sorry, I hit an issue');

    final statusBgColor = isDark
        ? (source == 'offline'
              ? const Color(0x2610B981)
              : const Color(0x266366F1))
        : (source == 'offline'
              ? const Color(0x1F059669)
              : const Color(0x1F4338CA));

    final statusBorderColor = isDark
        ? (source == 'offline'
              ? const Color(0x4010B981)
              : const Color(0x406366F1))
        : (source == 'offline'
              ? const Color(0x40059669)
              : const Color(0x404338CA));

    final statusTextColor = isDark
        ? (source == 'offline'
              ? const Color(0xFF34D399)
              : const Color(0xFF818CF8))
        : (source == 'offline'
              ? const Color(0xFF047857)
              : const Color(0xFF4338CA));

    final askCloudTextColor = isDark
        ? const Color(0xFF38BDF8)
        : const Color(0xFF0284C7);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[_buildRobotAvatar(), const SizedBox(width: 8)],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              child: Column(
                crossAxisAlignment: isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  PastelGradientCard(
                    type: isUser ? PastelCardType.sky : PastelCardType.violet,
                    borderRadius: 16,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: _buildMarkdownBody(text),
                  ),
                  const SizedBox(height: 4),
                  if (!isUser)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: statusBorderColor),
                            ),
                            child: Text(
                              source == 'offline' ? 'Offline' : 'Cloud',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: statusTextColor,
                              ),
                            ),
                          ),
                          if (source == 'offline')
                            GestureDetector(
                              onTap: () => _escalateQuery(text),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.cloud_sync_outlined,
                                    size: 12,
                                    color: askCloudTextColor,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Ask Cloud',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: askCloudTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // Message Actions Bar (Copy, Feedback, Voice Speaker)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Copy button
                              InkWell(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: text));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Copied response to clipboard',
                                      ),
                                      duration: Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(3.0),
                                  child: Icon(
                                    Icons.content_copy_rounded,
                                    size: 13,
                                    color: isDark
                                        ? Colors.white60
                                        : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              // Thumbs up
                              InkWell(
                                onTap: () => provider.setMessageFeedback(
                                  index,
                                  'helpful',
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(3.0),
                                  child: Icon(
                                    feedback == 'helpful'
                                        ? Icons.thumb_up_rounded
                                        : Icons.thumb_up_outlined,
                                    size: 13,
                                    color: feedback == 'helpful'
                                        ? AppColors.accentEmeraldLight
                                        : (isDark
                                              ? Colors.white60
                                              : const Color(0xFF475569)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              // Thumbs down
                              InkWell(
                                onTap: () => provider.setMessageFeedback(
                                  index,
                                  'unhelpful',
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(3.0),
                                  child: Icon(
                                    feedback == 'unhelpful'
                                        ? Icons.thumb_down_rounded
                                        : Icons.thumb_down_outlined,
                                    size: 13,
                                    color: feedback == 'unhelpful'
                                        ? Colors.redAccent
                                        : (isDark
                                              ? Colors.white60
                                              : const Color(0xFF475569)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              // TTS Voice Speaker
                              InkWell(
                                onTap: () => _speakResponse(text, index),
                                child: Padding(
                                  padding: const EdgeInsets.all(3.0),
                                  child: Icon(
                                    (_isSpeaking &&
                                            _speakingMessageIndex == index)
                                        ? Icons.volume_up_rounded
                                        : Icons.volume_mute_outlined,
                                    size: 14,
                                    color:
                                        (_isSpeaking &&
                                            _speakingMessageIndex == index)
                                        ? AppColors.accentEmeraldLight
                                        : (isDark
                                              ? Colors.white60
                                              : const Color(0xFF475569)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (isError)
                            GestureDetector(
                              onTap: () => provider.retryLastFailedMessage(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.redAccent.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.refresh_rounded,
                                      size: 11,
                                      color: Colors.redAccent,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      'Retry',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Lightweight Markdown-aware rich text rendering for bold, bullet lists, numbered steps, and paragraphs.
  Widget _buildMarkdownBody(String rawText) {
    final lines = rawText.split('\n');
    final List<Widget> children = [];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        children.add(const SizedBox(height: 4));
        continue;
      }

      // Bullet List (- or *)
      if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        final content = trimmed.substring(2);
        children.add(
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 3.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '• ',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Expanded(child: _parseFormattedInlineText(content)),
              ],
            ),
          ),
        );
      }
      // Numbered Step List (e.g. 1. 2.)
      else if (RegExp(r'^\d+\.\s+').hasMatch(trimmed)) {
        final match = RegExp(r'^(\d+\.)\s+(.*)$').firstMatch(trimmed);
        final numPrefix = match?.group(1) ?? '1.';
        final content = match?.group(2) ?? trimmed;
        children.add(
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 3.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$numPrefix ',
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Expanded(child: _parseFormattedInlineText(content)),
              ],
            ),
          ),
        );
      }
      // Headers (# or ##)
      else if (trimmed.startsWith('#')) {
        final content = trimmed.replaceAll(RegExp(r'^#+\s*'), '');
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              content,
              style: GoogleFonts.outfit(
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        );
      }
      // Standard Paragraph
      else {
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 3.0),
            child: _parseFormattedInlineText(trimmed),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  Widget _parseFormattedInlineText(String text) {
    final List<InlineSpan> spans = [];
    final RegExp exp = RegExp(r'\*\*(.*?)\*\*|\*(.*?)\*');
    int start = 0;

    for (final Match match in exp.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }

      if (match.group(1) != null) {
        // Bold
        spans.add(
          TextSpan(
            text: match.group(1),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
        );
      } else if (match.group(2) != null) {
        // Italic
        spans.add(
          TextSpan(
            text: match.group(2),
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              color: Color(0xFF0F172A),
            ),
          ),
        );
      }
      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return Text.rich(
      TextSpan(
        children: spans,
        style: GoogleFonts.inter(
          color: const Color(0xFF0F172A),
          fontSize: 14,
          height: 1.4,
        ),
      ),
    );
  }
}
