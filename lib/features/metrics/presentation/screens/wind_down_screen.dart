import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gerex/core/presentation/widgets/glass_container.dart';
import 'package:gerex/core/presentation/widgets/gerex_scaffold.dart';
import 'package:gerex/core/theme/app_theme.dart';

class WindDownScreen extends StatefulWidget {
  const WindDownScreen({super.key});

  @override
  State<WindDownScreen> createState() => _WindDownScreenState();
}

class _WindDownScreenState extends State<WindDownScreen> {
  VideoPlayerController? _audioController;
  bool _isPlaying = false;
  double _volume = 0.5;
  String _selectedSound = 'Rain';
  int _timerMinutes = 15;
  int _remainingSeconds = 0;
  Timer? _countdownTimer;
  bool _showBreathing = false;

  final Map<String, String> _soundUrls = {
    'Rain': 'https://www.soundjay.com/nature/sounds/rain-07.mp3',
    'Ocean': 'https://www.soundjay.com/nature/sounds/ocean-wave-1.mp3',
    'White Noise': 'https://www.soundjay.com/misc/sounds/white-noise-01.mp3',
    'Fan': 'https://www.soundjay.com/mechanical/sounds/ventilation-fan-1.mp3',
  };

  final Map<String, IconData> _soundIcons = {
    'Rain': Icons.cloud_rain_rounded,
    'Ocean': Icons.water_rounded,
    'White Noise': Icons.waves_rounded,
    'Fan': Icons.wind_power_rounded,
  };

  @override
  void initState() {
    super.initState();
    _initializePlayer(_selectedSound);
  }

  Future<void> _initializePlayer(String soundKey) async {
    _isPlaying = false;
    if (_audioController != null) {
      await _audioController!.dispose();
    }

    final url = _soundUrls[soundKey]!;
    _audioController = VideoPlayerController.networkUrl(Uri.parse(url));

    try {
      await _audioController!.initialize();
      await _audioController!.setLooping(true);
      await _audioController!.setVolume(_volume);
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Failed to initialize audio loop: $e');
    }
  }

  void _togglePlay() {
    if (_audioController == null || !_audioController!.value.isInitialized) return;

    setState(() {
      if (_isPlaying) {
        _audioController!.pause();
        _isPlaying = false;
        _stopCountdown();
      } else {
        _audioController!.play();
        _isPlaying = true;
        _startCountdown();
      }
    });
  }

  void _changeSound(String soundKey) async {
    setState(() {
      _selectedSound = soundKey;
    });
    await _initializePlayer(soundKey);
    if (_isPlaying) {
      _audioController!.play();
    }
  }

  void _changeVolume(double val) {
    setState(() {
      _volume = val;
    });
    _audioController?.setVolume(val);
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    if (_remainingSeconds == 0) {
      _remainingSeconds = _timerMinutes * 60;
    }

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _audioController?.pause();
          _isPlaying = false;
          _countdownTimer?.cancel();
        }
      });
    });
  }

  void _stopCountdown() {
    _countdownTimer?.cancel();
  }

  void _selectTimer(int minutes) {
    setState(() {
      _timerMinutes = minutes;
      _remainingSeconds = minutes * 60;
    });
    if (_isPlaying) {
      _startCountdown();
    }
  }

  String _formatTimerString() {
    final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _audioController?.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GerexScaffold(
      appBar: AppBar(
        title: Text(
          'Wind-Down Sanctuary',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textDarkHeading,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : AppColors.textDarkHeading),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF070B19), const Color(0xFF0F172A)]
                : [const Color(0xFFEEF2F6), const Color(0xFFE2E8F0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Toggle Options Tab
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTabButton('Ambient Sounds', !_showBreathing),
                      const SizedBox(width: 16),
                      _buildTabButton('Breathing Circle', _showBreathing),
                    ],
                  ),
                  const SizedBox(height: 32),

                  if (!_showBreathing) ...[
                    // Audio Player Dashboard
                    _buildAmbientPlayer(theme),
                  ] else ...[
                    // Guided Box Breathing Widget
                    const GuidedBreathingWidget(),
                  ],

                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, bool active) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showBreathing = label == 'Breathing Circle';
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: active ? GerexGradients.primaryCTA : null,
          color: active ? null : Colors.black.withValues(alpha: 0.05),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildAmbientPlayer(ThemeData theme) {
    final isInitialized = _audioController?.value.isInitialized ?? false;

    return GlassContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: 24,
      child: Column(
        children: [
          // Sound selection Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.4,
            ),
            itemCount: _soundUrls.length,
            itemBuilder: (context, index) {
              final key = _soundUrls.keys.elementAt(index);
              final isSelected = _selectedSound == key;
              final icon = _soundIcons[key]!;

              return GestureDetector(
                onTap: () => _changeSound(key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: isSelected
                        ? Colors.indigo.shade900.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.05),
                    border: Border.all(
                      color: isSelected ? Colors.indigoAccent : Colors.grey.withValues(alpha: 0.2),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        color: isSelected ? Colors.indigoAccent : Colors.grey.shade600,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        key,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: isSelected ? Colors.indigoAccent : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),

          // Timer Countdown & Trigger controls
          Text(
            _isPlaying ? _formatTimerString() : '${_timerMinutes}:00',
            style: GoogleFonts.outfit(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: Colors.indigoAccent,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sleep Timer Countdown',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Duration picker options
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [5, 10, 15, 30, 60].map((mins) {
              final isSelected = _timerMinutes == mins;
              return GestureDetector(
                onTap: () => _selectTimer(mins),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.indigoAccent : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.indigoAccent),
                  ),
                  child: Text(
                    '${mins}m',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.indigoAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          // Play Pause CTA
          GestureDetector(
            onTap: _togglePlay,
            child: CircleAvatar(
              radius: 36,
              backgroundColor: Colors.indigoAccent,
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Volume Slider control
          Row(
            children: [
              Icon(Icons.volume_down_rounded, color: Colors.grey.shade600),
              Expanded(
                child: Slider(
                  value: _volume,
                  min: 0.0,
                  max: 1.0,
                  activeColor: Colors.indigoAccent,
                  onChanged: isInitialized ? _changeVolume : null,
                ),
              ),
              Icon(Icons.volume_up_rounded, color: Colors.grey.shade600),
            ],
          ),
        ],
      ),
    );
  }
}

class GuidedBreathingWidget extends StatefulWidget {
  const GuidedBreathingWidget({super.key});

  @override
  State<GuidedBreathingWidget> createState() => _GuidedBreathingWidgetState();
}

class _GuidedBreathingWidgetState extends State<GuidedBreathingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _circleSizeAnimation;
  String _instructionText = 'Prepare';
  int _secondsLeft = 4;
  Timer? _timer;
  int _step = 0; // 0: inhale, 1: hold, 2: exhale, 3: hold

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _circleSizeAnimation = Tween<double>(begin: 100, end: 220).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    _startBreathingCycle();
  }

  void _startBreathingCycle() {
    _step = 0;
    _breathingController.forward();
    _instructionText = 'Breathe In';
    _secondsLeft = 4;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 1) {
          _secondsLeft--;
        } else {
          _secondsLeft = 4;
          _step = (_step + 1) % 4;

          switch (_step) {
            case 0:
              _instructionText = 'Breathe In';
              _breathingController.forward();
              break;
            case 1:
              _instructionText = 'Hold';
              break;
            case 2:
              _instructionText = 'Breathe Out';
              _breathingController.reverse();
              break;
            case 3:
              _instructionText = 'Hold';
              break;
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      borderRadius: 24,
      child: Column(
        children: [
          // Circle animation container
          SizedBox(
            height: 260,
            child: Center(
              child: AnimatedBuilder(
                animation: _circleSizeAnimation,
                builder: (context, child) {
                  return Container(
                    width: _circleSizeAnimation.value,
                    height: _circleSizeAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.indigoAccent.withValues(alpha: 0.4),
                          Colors.indigoAccent.withValues(alpha: 0.05),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.indigoAccent.withValues(alpha: 0.6),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.indigoAccent.withValues(alpha: 0.1),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '$_secondsLeft',
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Action step header
          Text(
            _instructionText,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.indigoAccent,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Keep your breathing relaxed and steady.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
