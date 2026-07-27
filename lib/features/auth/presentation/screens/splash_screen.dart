import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/gerex_scaffold.dart';
import '../../../../core/theme/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const GerexScaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center_rounded,
              size: 72,
              color: AppColors.accentEmeraldLight,
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.accentEmeraldLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

