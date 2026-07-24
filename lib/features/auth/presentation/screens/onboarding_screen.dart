import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import 'package:gerex/core/presentation/widgets/glass_container.dart';
import 'package:gerex/core/presentation/widgets/liquid_background.dart';
import 'package:gerex/core/theme/app_theme.dart';
import 'package:gerex/core/presentation/utils/responsive_helper.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const _storage = FlutterSecureStorage();

  static const List<OnboardingData> _pages = [
    OnboardingData(
      icon: FontAwesomeIcons.dumbbell,
      title: 'Track Workouts',
      description:
          'Log your sets, reps, and weights easily with our fluid, modern glass interface designed for performance.',
    ),
    OnboardingData(
      icon: FontAwesomeIcons.robot,
      title: 'AI Fitness Coach',
      description:
          'Get custom weekly splits, real-time pose tracking feedback, and immediate coaching advice powered by Gemini.',
    ),
    OnboardingData(
      icon: FontAwesomeIcons.chartLine,
      title: 'Analyze Progress',
      description:
          'Visualize your gym streaks, calendar consistencies, and body metrics metrics progression over time.',
    ),
  ];

  Future<void> _completeOnboarding() async {
    await _storage.write(key: 'onboarding_completed', value: 'true');
    if (mounted) {
      Provider.of<AuthProvider>(context, listen: false).completeOnboarding();
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: LiquidBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar with Skip Button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_currentPage < _pages.length - 1)
                      TextButton(
                        onPressed: _completeOnboarding,
                        child: Text(
                          'Skip',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Swipeable Page View
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (int index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final data = _pages[index];
                    return Center(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24.0,
                            vertical: 16.0,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Glowing Icon Wrapper
                              Container(
                                padding: EdgeInsets.all(
                                  context.responsive.select(
                                    smallPhone: 20.0,
                                    standardPhone: 28.0,
                                    largePhone: 32.0,
                                    tablet: 40.0,
                                  ),
                                ),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      theme.colorScheme.primary.withValues(
                                        alpha: 0.15,
                                      ),
                                      Colors.transparent,
                                    ],
                                    radius: 0.7,
                                  ),
                                ),
                                child: FaIcon(
                                  data.icon,
                                  size: context.responsive.select(
                                    smallPhone: 56.0,
                                    standardPhone: 72.0,
                                    largePhone: 80.0,
                                    tablet: 96.0,
                                  ),
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              SizedBox(height: context.h(4)),

                              // Glass card containing description
                              GlassContainer(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      data.title,
                                      style: theme.textTheme.headlineMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.5,
                                            fontSize: context.sp(22),
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      data.description,
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.7),
                                            height: 1.5,
                                            fontSize: context.sp(14),
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Page Indicator & CTA Actions
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Dynamic indicators row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (index) {
                        final isActive = _currentPage == index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          height: 8.0,
                          width: isActive ? 24.0 : 8.0,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4.0),
                            color: isActive
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.2,
                                  ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 32),

                    // Primary Onboarding CTA Action Button
                    InkWell(
                      onTap: () {
                        if (_currentPage < _pages.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOutCubic,
                          );
                        } else {
                          _completeOnboarding();
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: GerexGradients.primaryCTA,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _currentPage == _pages.length - 1
                                ? 'Get Started'
                                : 'Next',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
    );
  }
}

class OnboardingData {
  final dynamic icon;
  final String title;
  final String description;

  const OnboardingData({
    required this.icon,
    required this.title,
    required this.description,
  });
}
