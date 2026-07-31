import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/progress_photos_provider.dart';
import '../../domain/entities/progress_photo.dart';
import '../../../metrics/presentation/providers/metrics_provider.dart';
import 'package:gerex/core/presentation/widgets/glass_container.dart';
import 'package:gerex/core/presentation/widgets/pastel_gradient_card.dart';
import 'package:gerex/core/presentation/widgets/gerex_scaffold.dart';
import 'package:gerex/core/presentation/widgets/gerex_line_chart.dart';
import 'package:gerex/core/presentation/widgets/gerex_button.dart';
import 'package:gerex/core/theme/app_theme.dart';

class ProgressComparisonScreen extends StatefulWidget {
  const ProgressComparisonScreen({super.key});

  @override
  State<ProgressComparisonScreen> createState() => _ProgressComparisonScreenState();
}

class _ProgressComparisonScreenState extends State<ProgressComparisonScreen> {
  int? _startMonth;
  int? _startYear;
  int? _endMonth;
  int? _endYear;

  bool _isComparing = false;
  String _activeTab = 'Photo'; // 'Photo' or 'Statistic'

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  final List<int> _years = [2025, 2026];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photoProvider = Provider.of<ProgressPhotosProvider>(context);
    final metricsProvider = Provider.of<MetricsProvider>(context);

    if (_isComparing) {
      return _buildResultView(theme, photoProvider, metricsProvider);
    }

    final isCompareEnabled = _startMonth != null && _startYear != null && _endMonth != null && _endYear != null;

    return GerexScaffold(
      appBar: AppBar(
        title: Text(
          'Compare Progress',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textDarkHeading,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Text(
                'Select Months to Compare',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Track changes in your physique and body logs over time.',
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Baseline Month Picker
              Text('Baseline Month', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.primary)),
              const SizedBox(height: 8),
              PastelGradientCard(
                type: PastelCardType.sky,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButton<int>(
                        value: _startMonth,
                        hint: const Text('Select Month'),
                        underline: const SizedBox.shrink(),
                        isExpanded: true,
                        items: List.generate(12, (index) {
                          return DropdownMenuItem(value: index + 1, child: Text(_months[index]));
                        }),
                        onChanged: (val) => setState(() => _startMonth = val),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButton<int>(
                        value: _startYear,
                        hint: const Text('Select Year'),
                        underline: const SizedBox.shrink(),
                        isExpanded: true,
                        items: _years.map((year) {
                          return DropdownMenuItem(value: year, child: Text(year.toString()));
                        }).toList(),
                        onChanged: (val) => setState(() => _startYear = val),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Comparison Target Month Picker
              Text('Comparison Month', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.primary)),
              const SizedBox(height: 8),
              PastelGradientCard(
                type: PastelCardType.sky,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButton<int>(
                        value: _endMonth,
                        hint: const Text('Select Month'),
                        underline: const SizedBox.shrink(),
                        isExpanded: true,
                        items: List.generate(12, (index) {
                          return DropdownMenuItem(value: index + 1, child: Text(_months[index]));
                        }),
                        onChanged: (val) => setState(() => _endMonth = val),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButton<int>(
                        value: _endYear,
                        hint: const Text('Select Year'),
                        underline: const SizedBox.shrink(),
                        isExpanded: true,
                        items: _years.map((year) {
                          return DropdownMenuItem(value: year, child: Text(year.toString()));
                        }).toList(),
                        onChanged: (val) => setState(() => _endYear = val),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Compare button
              Container(
                decoration: BoxDecoration(
                  gradient: isCompareEnabled ? GerexGradients.primaryCTA : null,
                  color: isCompareEnabled ? null : theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: isCompareEnabled
                      ? () {
                          // Fetch latest weight logs
                          metricsProvider.fetchWeightLogs();
                          setState(() {
                            _isComparing = true;
                          });
                        }
                      : null,
                  child: const Text(
                    'Compare Progress',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
    );
  }

  Widget _buildResultView(ThemeData theme, ProgressPhotosProvider photoProvider, MetricsProvider metricsProvider) {
    // Filter matching photos
    final startPhotos = photoProvider.photos.where((p) => p.createdAt.month == _startMonth && p.createdAt.year == _startYear).toList();
    final endPhotos = photoProvider.photos.where((p) => p.createdAt.month == _endMonth && p.createdAt.year == _endYear).toList();

    return GerexScaffold(
      appBar: AppBar(
        title: Text(
          'Compare Progress',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textDarkHeading,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppColors.accentEmeraldLight),
            onPressed: () {
              setState(() {
                _startMonth = null;
                _startYear = null;
                _endMonth = null;
                _endYear = null;
                _isComparing = false;
              });
            },
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: PastelGradientCard(
              type: PastelCardType.slate,
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(child: _buildTabButton('Photo')),
                  Expanded(child: _buildTabButton('Statistic')),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              child: _activeTab == 'Photo'
                  ? _buildPhotoView(theme, startPhotos, endPhotos)
                  : _buildStatisticView(theme, metricsProvider),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tabName) {
    final isSelected = tabName == _activeTab;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => setState(() => _activeTab = tabName),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          tabName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF14181F).withValues(alpha: 0.6),
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoView(ThemeData theme, List<ProgressPhoto> startPhotos, List<ProgressPhoto> endPhotos) {
    final poses = ['Front', 'Back', 'Left', 'Right'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Average progress percentage progress bar
        PastelGradientCard(
          type: PastelCardType.sky,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Average Progress', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF14181F))),
                  Text(
                    'Great Change',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0284C7)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: 0.72,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Angle grids
        ...poses.map((pose) {
          final startPhoto = startPhotos.cast<ProgressPhoto?>().firstWhere((p) => p?.pose == pose, orElse: () => null);
          final endPhoto = endPhotos.cast<ProgressPhoto?>().firstWhere((p) => p?.pose == pose, orElse: () => null);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text('$pose Facing Angle', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildComparisonPhotoBox(
                      theme,
                      startPhoto,
                      '${_months[_startMonth! - 1]} $_startYear',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildComparisonPhotoBox(
                      theme,
                      endPhoto,
                      '${_months[_endMonth! - 1]} $_endYear',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildComparisonPhotoBox(ThemeData theme, ProgressPhoto? photo, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 1.0,
          child: GlassContainer(
            padding: EdgeInsets.zero,
            child: photo == null
                ? Center(
                    child: Text(
                      'No photo captured\nfor this angle',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: photo.signedUrl.startsWith('http')
                        ? Image.network(photo.signedUrl, fit: BoxFit.cover)
                        : Image.file(File(photo.signedUrl), fit: BoxFit.cover),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            label,
            style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticView(ThemeData theme, MetricsProvider metricsProvider) {
    final startWeightList = metricsProvider.weightLogs.where((l) => l.loggedAt.month == _startMonth && l.loggedAt.year == _startYear).toList();
    final endWeightList = metricsProvider.weightLogs.where((l) => l.loggedAt.month == _endMonth && l.loggedAt.year == _endYear).toList();

    final double startAvg = startWeightList.isNotEmpty
        ? (startWeightList.map((l) => l.value).reduce((a, b) => a + b) / startWeightList.length)
        : 78.0; // default template fallback if database empty
    final double endAvg = endWeightList.isNotEmpty
        ? (endWeightList.map((l) => l.value).reduce((a, b) => a + b) / endWeightList.length)
        : 75.2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Custom painting weight comparison graph
        PastelGradientCard(
          type: PastelCardType.sky,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Weight Progression Trend',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF14181F)),
              ),
              const SizedBox(height: 12),
              GerexLineChart(
                data: [
                  GerexLineChartPoint(label: 'Baseline', value: startAvg),
                  GerexLineChartPoint(label: 'Midpoint', value: (startAvg + endAvg) / 2),
                  GerexLineChartPoint(label: 'Target', value: endAvg),
                ],
                unit: 'kg',
                height: 180,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Weight metric before/after bar
        Text(
          'Tracked Body Weight',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.textDarkHeading),
        ),
        const SizedBox(height: 12),
        PastelGradientCard(
          type: PastelCardType.sunset,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProgressMetricBar(theme, 'Baseline Weight', startAvg, 'kg', const Color(0xFFEA580C)),
              const SizedBox(height: 16),
              _buildProgressMetricBar(theme, 'Comparison Weight', endAvg, 'kg', const Color(0xFFD97706)),
            ],
          ),
        ),

        const SizedBox(height: 40),

        GerexButton(
          text: 'Back to Home Dashboard',
          onPressed: () => context.go('/'),
        ),
      ],
    );
  }

  Widget _buildProgressMetricBar(ThemeData theme, String label, double value, String unit, Color color) {
    const double maxPossibleWeight = 150.0;
    final double fraction = (value / maxPossibleWeight).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF14181F))),
            Text('${value.toStringAsFixed(1)} $unit', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF14181F))),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 8,
            backgroundColor: Colors.white.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
