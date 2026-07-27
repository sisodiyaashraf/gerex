import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_theme.dart';

class SlideToConfirmButton extends StatefulWidget {
  final String label;
  final VoidCallback onConfirm;
  final double height;
  final Gradient? knobGradient;
  final Gradient? trackGradient;
  final Color? trackColor;
  final dynamic knobIcon;
  final dynamic successIcon;
  final Color iconColor;
  final Color successIconColor;
  final TextStyle? labelStyle;

  const SlideToConfirmButton({
    super.key,
    required this.label,
    required this.onConfirm,
    this.height = 56.0,
    this.knobGradient,
    this.trackGradient,
    this.trackColor,
    this.knobIcon = FontAwesomeIcons.anglesRight,
    this.successIcon = FontAwesomeIcons.check,
    this.iconColor = Colors.white,
    this.successIconColor = Colors.white,
    this.labelStyle,
  });

  @override
  State<SlideToConfirmButton> createState() => _SlideToConfirmButtonState();
}

class _SlideToConfirmButtonState extends State<SlideToConfirmButton>
    with SingleTickerProviderStateMixin {
  double _dragPosition = 0.0;
  bool _isConfirmed = false;
  late AnimationController _snapController;
  late Animation<double> _snapAnimation;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _snapAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _snapController, curve: Curves.easeOutCubic),
    )..addListener(() {
        if (!_isConfirmed) {
          setState(() {
            _dragPosition = _snapAnimation.value;
          });
        }
      });
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details, double maxDragWidth) {
    if (_isConfirmed) return;
    setState(() {
      _dragPosition += details.delta.dx;
      if (_dragPosition < 0.0) _dragPosition = 0.0;
      if (_dragPosition > maxDragWidth) _dragPosition = maxDragWidth;
    });
  }

  void _onDragEnd(DragEndDetails details, double maxDragWidth) {
    if (_isConfirmed) return;
    
    // Check if the user dragged it far enough to confirm (e.g. 95% of total path)
    if (_dragPosition >= maxDragWidth * 0.95) {
      _confirm(maxDragWidth);
    } else {
      // Snap back
      _snapAnimation = Tween<double>(begin: _dragPosition, end: 0.0).animate(
        CurvedAnimation(parent: _snapController, curve: Curves.easeOutCubic),
      );
      _snapController.forward(from: 0.0);
    }
  }

  Future<void> _confirm(double targetPosition) async {
    setState(() {
      _isConfirmed = true;
      _dragPosition = targetPosition;
    });

    // Short haptic tap
    await HapticFeedback.mediumImpact();

    // Small delay to show success animation state before executing action
    await Future.delayed(const Duration(milliseconds: 400));
    
    widget.onConfirm();

    // Reset state in case screen is popped and returned
    if (mounted) {
      setState(() {
        _isConfirmed = false;
        _dragPosition = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final finalKnobGradient = widget.knobGradient ?? GerexGradients.primaryCTA;
    final finalTrackColor = widget.trackColor ?? 
        (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03));
    final finalTrackGradient = widget.trackGradient;

    final double knobSize = widget.height - 8.0;

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: finalTrackGradient == null ? finalTrackColor : null,
        gradient: finalTrackGradient,
        borderRadius: BorderRadius.circular(widget.height / 2),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
          width: 1.0,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxDragWidth = constraints.maxWidth - knobSize - 8.0; // 4px padding on each side

          // Ensure drag position doesn't overflow if container layout changes
          if (_dragPosition > maxDragWidth && !_isConfirmed) {
            _dragPosition = maxDragWidth;
          }

          // Compute label opacity based on slider progress
          double progress = maxDragWidth > 0 ? _dragPosition / maxDragWidth : 0.0;
          double labelOpacity = (1.0 - progress * 2.0).clamp(0.0, 1.0);

          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Sliding background highlight (fills track behind knob)
              Positioned(
                left: 4,
                child: AnimatedContainer(
                  duration: _isConfirmed ? const Duration(milliseconds: 200) : Duration.zero,
                  width: _dragPosition + knobSize,
                  height: widget.height - 8,
                  decoration: BoxDecoration(
                    gradient: _isConfirmed 
                        ? finalKnobGradient 
                        : LinearGradient(
                            colors: [
                              finalKnobGradient.colors.first.withValues(alpha: 0.3),
                              finalKnobGradient.colors.last.withValues(alpha: 0.1),
                            ],
                          ),
                    borderRadius: BorderRadius.circular((widget.height - 8) / 2),
                  ),
                ),
              ),

              // Center label text
              Align(
                alignment: Alignment.center,
                child: Opacity(
                  opacity: _isConfirmed ? 0.0 : labelOpacity,
                  child: Text(
                    widget.label,
                    style: widget.labelStyle ?? TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),

              // Draggable Knob
              Positioned(
                left: 4.0 + _dragPosition,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) => _onDragUpdate(details, maxDragWidth),
                  onHorizontalDragEnd: (details) => _onDragEnd(details, maxDragWidth),
                  child: Container(
                    width: knobSize,
                    height: knobSize,
                    decoration: BoxDecoration(
                      gradient: finalKnobGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: finalKnobGradient.colors.first.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                        child: _isConfirmed
                            ? FaIcon(
                                widget.successIcon as FaIconData?,
                                key: const ValueKey('successIcon'),
                                color: widget.successIconColor,
                                size: widget.height * 0.35,
                              )
                            : FaIcon(
                                widget.knobIcon as FaIconData?,
                                key: const ValueKey('knobIcon'),
                                color: widget.iconColor,
                                size: widget.height * 0.32,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
