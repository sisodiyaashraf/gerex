import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class StreakFlameWidget extends StatefulWidget {
  final int streakCount;
  final bool isTodayLogged;
  final bool animate;

  const StreakFlameWidget({
    super.key,
    required this.streakCount,
    required this.isTodayLogged,
    this.animate = true,
  });

  @override
  State<StreakFlameWidget> createState() => _StreakFlameWidgetState();
}

class _StreakFlameWidgetState extends State<StreakFlameWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.25), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.25, end: 1.0), weight: 50),
    ]).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _rotateAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: -0.12), weight: 25),
      TweenSequenceItem(tween: Tween<double>(begin: -0.12, end: 0.12), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 0.12, end: 0.0), weight: 25),
    ]).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.animate) {
      if (widget.isTodayLogged) {
        _controller.forward();
      } else {
        _controller.repeat(reverse: true);
      }
    }
  }

  @override
  void didUpdateWidget(StreakFlameWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isTodayLogged != widget.isTodayLogged || oldWidget.streakCount != widget.streakCount) {
      if (widget.animate) {
        _controller.reset();
        if (widget.isTodayLogged) {
          _controller.forward();
        } else {
          _controller.repeat(reverse: true);
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double baseSize = 22.0;
    final double growth = (widget.streakCount * 1.0).clamp(0.0, 12.0);
    final double finalSize = baseSize + growth;

    final Color flameColor = widget.isTodayLogged
        ? Color.lerp(const Color(0xFFF97316), const Color(0xFFEF4444), (widget.streakCount / 20).clamp(0.0, 1.0))!
        : const Color(0xFF94A3B8);

    final Color glowColor = widget.isTodayLogged
        ? flameColor.withOpacity(0.35)
        : Colors.transparent;

    Widget flameIcon = FaIcon(
      FontAwesomeIcons.fire,
      color: flameColor,
      size: finalSize,
    );

    if (widget.animate) {
      flameIcon = AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotateAnimation.value,
            child: Transform.scale(
              scale: _pulseAnimation.value,
              child: child,
            ),
          );
        },
        child: flameIcon,
      );
    }

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: widget.isTodayLogged
            ? [
                BoxShadow(
                  color: glowColor,
                  blurRadius: 10 + growth,
                  spreadRadius: 2 + (growth / 4),
                ),
              ]
            : null,
      ),
      child: flameIcon,
    );
  }
}
