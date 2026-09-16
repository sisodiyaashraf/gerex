import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/gerex_scaffold.dart';
import '../../../../core/theme/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-screen background image covering all edges
          Image.asset(
            'assets/images/app icon/gerex splash_screen.jpeg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: AppColors.bgDarkPrimary,
                child: const Center(
                  child: Icon(
                    Icons.fitness_center_rounded,
                    size: 80,
                    color: AppColors.accentEmeraldLight,
                  ),
                ),
              );
            },
          ),

          // Subtle gradient overlay at the bottom for smooth indicator readability
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 160,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.6),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Bottom progress indicator
          const Positioned(
            left: 0,
            right: 0,
            bottom: 48,
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.accentEmeraldLight,
                ),
                strokeWidth: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


