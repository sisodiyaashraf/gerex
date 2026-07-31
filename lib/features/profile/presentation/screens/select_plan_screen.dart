import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gerex/core/presentation/widgets/glass_container.dart';
import 'package:gerex/core/presentation/widgets/pastel_gradient_card.dart';
import 'package:gerex/core/presentation/widgets/gerex_scaffold.dart';
import 'package:gerex/core/presentation/widgets/gerex_button.dart';
import 'package:gerex/core/theme/app_theme.dart';

class SelectPlanScreen extends StatefulWidget {
  const SelectPlanScreen({super.key});

  @override
  State<SelectPlanScreen> createState() => _SelectPlanScreenState();
}

class _SelectPlanScreenState extends State<SelectPlanScreen> {
  bool _isAnnual = true;

  void _showComingSoonDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          content: GlassContainer(
            padding: const EdgeInsets.all(24),
            borderRadius: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppColors.chipGreenBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.payments_outlined,
                    color: AppColors.accentEmeraldLight,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Coming Soon!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDarkHeading),
                ),
                const SizedBox(height: 12),
                Text(
                  'Premium subscription plans are currently under development. Real payment integration will be wired up in a future update.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textDarkMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                GerexButton(
                  text: 'Got it',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    const double monthlyPrice = 9.99;
    const double annualPrice = 89.99;

    return GerexScaffold(
      appBar: AppBar(
        title: Text(
          'Choose Your Plan',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textDarkHeading,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: CustomScrollView(
          slivers: [
            // Dark Gradient Hero Header
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              backgroundColor: Colors.transparent,
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.4),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: GerexGradients.scaffoldBackground,
                      ),
                    ),
                    Positioned(
                      left: 24,
                      bottom: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gerex Premium',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textDarkHeading,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Unlock your ultimate athletic aesthetic',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textDarkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Toggle Switch
                  Center(
                    child: GlassContainer(
                      padding: const EdgeInsets.all(4),
                      borderRadius: 20,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _isAnnual = false),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: !_isAnnual ? AppColors.accentEmeraldLight : Colors.transparent,
                              ),
                              child: Text(
                                'Monthly',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: !_isAnnual ? Colors.white : AppColors.textDarkMuted,
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _isAnnual = true),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: _isAnnual ? AppColors.accentEmeraldLight : Colors.transparent,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'Annual',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _isAnnual ? Colors.white : AppColors.textDarkMuted,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.badgeDarkNavy,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Save 25%',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.accentEmeraldLight,
                                      ),
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

                  const SizedBox(height: 24),

                  // Selected Plan Card
                  _buildPlanCard(
                    context: context,
                    title: _isAnnual ? 'Annual Membership' : 'Monthly Membership',
                    priceText: _isAnnual 
                        ? '\$${annualPrice.toStringAsFixed(2)}/yr' 
                        : '\$${monthlyPrice.toStringAsFixed(2)}/mo',
                    termsText: _isAnnual 
                        ? 'Billed once at \$${annualPrice.toStringAsFixed(2)}, renews unless cancelled' 
                        : 'Billed once at \$${monthlyPrice.toStringAsFixed(2)}, renews unless cancelled',
                    savingsLabel: _isAnnual ? 'Best Value: \$7.50 / month' : null,
                  ),

                  const SizedBox(height: 24),

                  // Feature Checklist
                  const Text(
                    'All Unlocked Features',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  PastelGradientCard(
                    type: PastelCardType.indigo,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildFeatureRow(theme, 'Unlimited Live Workout Logging'),
                        const SizedBox(height: 12),
                        _buildFeatureRow(theme, 'Interactive AI Fitness Coach & Planner'),
                        const SizedBox(height: 12),
                        _buildFeatureRow(theme, 'Advanced Sleep Cycle & Alarm Tracking'),
                        const SizedBox(height: 12),
                        _buildFeatureRow(theme, 'Unlimited Community Challenges Participation'),
                        const SizedBox(height: 12),
                        _buildFeatureRow(theme, 'Weight Volume & Progress Metrics Dashboard'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Subscription button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: GerexGradients.primaryCTA,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _showComingSoonDialog,
                        child: const Text(
                          'Upgrade Membership Now',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),
                ]),
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildPlanCard({
    required BuildContext context,
    required String title,
    required String priceText,
    required String termsText,
    String? savingsLabel,
  }) {
    final theme = Theme.of(context);
    return PastelGradientCard(
      type: PastelCardType.indigo,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (savingsLabel != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    savingsLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            priceText,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            termsText,
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF14181F).withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(ThemeData theme, String feature) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle_outline_rounded,
          color: theme.colorScheme.primary,
          size: 18,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            feature,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}