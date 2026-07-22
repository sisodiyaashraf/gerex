import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ai_provider.dart';
import 'package:gerex/core/presentation/widgets/glass_container.dart';
import 'package:gerex/core/presentation/widgets/liquid_background.dart';

class AIPlanGeneratorScreen extends StatefulWidget {
  const AIPlanGeneratorScreen({super.key});

  @override
  State<AIPlanGeneratorScreen> createState() => _AIPlanGeneratorScreenState();
}

class _AIPlanGeneratorScreenState extends State<AIPlanGeneratorScreen> {
  String _goal = 'Muscle Gain';
  String _equipment = 'Full Gym';
  String _experience = 'Intermediate';

  final List<String> _goals = ['Muscle Gain', 'Fat Loss', 'Strength & Endurance'];
  final List<String> _equipments = [
    'Full Gym',
    'Dumbbells Only',
    'Bodyweight Only',
  ];
  final List<String> _experiences = ['Beginner', 'Intermediate', 'Advanced'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<AIProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Plan Generator'),
      ),
      body: LiquidBackground(
        child: provider.isPlanLoading
            ? _buildLoadingState(theme)
            : provider.generatedWorkoutPlan != null
                ? _buildPlanDisplay(theme, provider)
                : _buildGeneratorForm(theme, provider),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Assembling Your Weekly Plan...',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gemini is analyzing your selections to construct optimal gym splits, sets target volume, and rest metrics.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanDisplay(ThemeData theme, AIProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Custom Plan',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Regenerate'),
                onPressed: () => provider.clearCachedPlan(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GlassContainer(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Text(
                  provider.generatedWorkoutPlan!,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratorForm(ThemeData theme, AIProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 64,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Generate Weekly Workout Program',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Answer a few quick questions to receive a weekly fitness schedule built by Gemini.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Error Display
          if (provider.planError != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                provider.planError!,
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Form fields Dropdowns
          DropdownButtonFormField<String>(
            initialValue: _goal,
            decoration: const InputDecoration(
              labelText: 'Training Goal',
              border: OutlineInputBorder(),
            ),
            items: _goals
                .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                .toList(),
            onChanged: (val) => setState(() => _goal = val ?? 'Muscle Gain'),
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: _equipment,
            decoration: const InputDecoration(
              labelText: 'Available Equipment',
              border: OutlineInputBorder(),
            ),
            items: _equipments
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (val) =>
                setState(() => _equipment = val ?? 'Full Gym'),
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: _experience,
            decoration: const InputDecoration(
              labelText: 'Experience Level',
              border: OutlineInputBorder(),
            ),
            items: _experiences
                .map((ex) => DropdownMenuItem(value: ex, child: Text(ex)))
                .toList(),
            onChanged: (val) =>
                setState(() => _experience = val ?? 'Intermediate'),
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () {
              provider.generatePlan(
                goal: _goal,
                equipment: _equipment,
                experienceLevel: _experience,
              );
            },
            child: const Text(
              'Generate Weekly Plan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
