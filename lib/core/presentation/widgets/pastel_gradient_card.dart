import 'package:flutter/material.dart';

enum PastelCardType {
  mint,
  indigo,
  sky,
  violet,
  sunset,
  rose,
  slate,
}

class PastelGradientCard extends StatelessWidget {
  final Widget child;
  final PastelCardType type;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;

  const PastelGradientCard({
    super.key,
    required this.child,
    required this.type,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getGradientColors(type);
    final glowColor = _getGlowColor(type);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          padding: padding,
          child: DefaultTextStyle.merge(
            style: const TextStyle(
              color: Color(0xFF14181F), // WCAG AAA near-black contrast
              fontWeight: FontWeight.w500,
            ),
            child: IconTheme.merge(
              data: const IconThemeData(
                color: Color(0xFF14181F), // High contrast icons
                size: 20,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  List<Color> _getGradientColors(PastelCardType cardType) {
    switch (cardType) {
      case PastelCardType.mint:
        return const [Color(0xFFB9F3DC), Color(0xFFF3FFFB)];
      case PastelCardType.indigo:
        return const [Color(0xFFD8D6FA), Color(0xFFF3F1FF)];
      case PastelCardType.sky:
        return const [Color(0xFFCDEBFA), Color(0xFFF0FAFF)];
      case PastelCardType.violet:
        return const [Color(0xFFE3D9F7), Color(0xFFF6F1FF)];
      case PastelCardType.sunset:
        return const [Color(0xFFFFEFC2), Color(0xFFFFFAEA)];
      case PastelCardType.rose:
        return const [Color(0xFFFCD9DE), Color(0xFFFFF3F5)];
      case PastelCardType.slate:
        return const [Color(0xFFE2E8F0), Color(0xFFFFFFFF)];
    }
  }

  Color _getGlowColor(PastelCardType cardType) {
    switch (cardType) {
      case PastelCardType.mint:
        return const Color(0xFF10B981);
      case PastelCardType.indigo:
        return const Color(0xFF6366F1);
      case PastelCardType.sky:
        return const Color(0xFF0EA5E9);
      case PastelCardType.violet:
        return const Color(0xFF8B5CF6);
      case PastelCardType.sunset:
        return const Color(0xFFF59E0B);
      case PastelCardType.rose:
        return const Color(0xFFF43F5E);
      case PastelCardType.slate:
        return const Color(0xFF64748B);
    }
  }
}
