import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/progress_photos_provider.dart';
import '../../domain/entities/progress_photo.dart';
import 'package:gerex/core/presentation/widgets/glass_container.dart';
import 'package:gerex/core/presentation/widgets/gerex_scaffold.dart';
import 'package:gerex/core/theme/app_theme.dart';
import 'package:gerex/core/presentation/utils/responsive_helper.dart';

class ProgressPhotosScreen extends StatefulWidget {
  const ProgressPhotosScreen({super.key});

  @override
  State<ProgressPhotosScreen> createState() => _ProgressPhotosScreenState();
}

class _ProgressPhotosScreenState extends State<ProgressPhotosScreen> {
  bool _showReminderBanner = true;
  bool _compareMode = false;
  final Set<ProgressPhoto> _selectedForCompare = {};

  void _showImageSourceSelector(BuildContext context, ProgressPhotosProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GlassContainer(
        borderRadius: 24,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Add Progress Photo',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceButton(
                  context,
                  icon: FontAwesomeIcons.camera,
                  label: 'Camera',
                  onTap: () async {
                    Navigator.pop(ctx);
                    final err = await provider.addProgressPhoto(ImageSource.camera);
                    if (err != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                    }
                  },
                ),
                _buildSourceButton(
                  context,
                  icon: FontAwesomeIcons.images,
                  label: 'Gallery',
                  onTap: () async {
                    Navigator.pop(ctx);
                    final err = await provider.addProgressPhoto(ImageSource.gallery);
                    if (err != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceButton(BuildContext context, {required dynamic icon, required String label, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            FaIcon(icon as FaIconData, size: 24, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context, ProgressPhotosProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        content: GlassContainer(
          padding: const EdgeInsets.all(20),
          borderRadius: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Reminder Settings',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Enable Reminders'),
                  Switch.adaptive(
                    value: provider.remindersEnabled,
                    onChanged: (val) {
                      provider.setRemindersEnabled(val);
                    },
                  ),
                ],
              ),
              if (provider.remindersEnabled) ...[
                const SizedBox(height: 12),
                const Text('Reminder Cadence', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'weekly', label: Text('Weekly')),
                    ButtonSegment(value: 'monthly', label: Text('Monthly')),
                  ],
                  selected: {provider.reminderCadence},
                  onSelectionChanged: (selection) {
                    provider.setReminderCadence(selection.first);
                  },
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCompareView() {
    if (_selectedForCompare.length != 2) return;
    final list = _selectedForCompare.toList();
    // Sort so earlier date is first (Before)
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    showDialog(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: Colors.black.withValues(alpha: 0.9),
        child: Column(
          children: [
            SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                  const Text(
                    'Before & After Compare',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: context.isTablet
                    ? Row(
                        children: [
                          Expanded(child: _buildCompareItem(list[0], 'BEFORE')),
                          const SizedBox(width: 16),
                          Expanded(child: _buildCompareItem(list[1], 'AFTER')),
                        ],
                      )
                    : Column(
                        children: [
                          Expanded(child: _buildCompareItem(list[0], 'BEFORE')),
                          const SizedBox(width: 16),
                          Expanded(child: _buildCompareItem(list[1], 'AFTER')),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompareItem(ProgressPhoto photo, String label) {
    final hasHttp = photo.signedUrl.startsWith('http');
    return Card(
      color: Colors.transparent,
      elevation: 0,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
            decoration: BoxDecoration(
              color: label == 'BEFORE' ? Colors.redAccent.withValues(alpha: 0.8) : Colors.greenAccent.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: hasHttp
                  ? Image.network(
                      photo.signedUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (c, e, s) => const Center(
                        child: Icon(Icons.broken_image, color: Colors.grey, size: 48),
                      ),
                    )
                  : Image.file(
                      File(photo.signedUrl),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (c, e, s) => const Center(
                        child: Icon(Icons.broken_image, color: Colors.grey, size: 48),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${photo.createdAt.day}/${photo.createdAt.month}/${photo.createdAt.year}',
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<ProgressPhotosProvider>(context);

    return GerexScaffold(
      appBar: AppBar(
        title: Text(
          'Progress Photos',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textDarkHeading,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_rounded, color: AppColors.accentEmeraldLight),
            onPressed: () => context.push('/guided-capture'),
          ),
          IconButton(
            icon: const Icon(Icons.compare_arrows_rounded, color: AppColors.accentEmeraldLight),
            onPressed: () => context.push('/progress-compare'),
          ),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.sliders, size: 16, color: AppColors.textDarkHeading),
            onPressed: () => _showSettingsDialog(context, provider),
          ),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (_showReminderBanner && provider.nextReminderDate != null) ...[
                    GlassContainer(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, color: theme.colorScheme.primary),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Next Progress Photo',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Scheduled for: ${provider.nextReminderDate!.day}/${provider.nextReminderDate!.month}/${provider.nextReminderDate!.year}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () => setState(() => _showReminderBanner = false),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Compare Mode toggle bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _compareMode ? 'Select 2 photos to compare' : 'My Gallery',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        icon: FaIcon(
                          _compareMode ? FontAwesomeIcons.xmark : FontAwesomeIcons.solidSquareCheck,
                          size: 14,
                        ),
                        label: Text(_compareMode ? 'Cancel' : 'Compare Before/After'),
                        onPressed: () {
                          setState(() {
                            _compareMode = !_compareMode;
                            _selectedForCompare.clear();
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (provider.photos.isEmpty) ...[
                    const SizedBox(height: 80),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo_library_outlined, size: 64, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                          const SizedBox(height: 16),
                          const Text(
                            'No Progress Photos Yet',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Capture photos regularly to visual-track details',
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ]),
              ),
            ),
            if (provider.photos.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: context.isTablet ? 3 : 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final photo = provider.photos[index];
                      final isSelected = _selectedForCompare.contains(photo);
                      final hasHttp = photo.signedUrl.startsWith('http');

                      return GestureDetector(
                        onTap: () {
                          if (_compareMode) {
                            setState(() {
                              if (isSelected) {
                                _selectedForCompare.remove(photo);
                              } else {
                                if (_selectedForCompare.length < 2) {
                                  _selectedForCompare.add(photo);
                                  if (_selectedForCompare.length == 2) {
                                    _openCompareView();
                                  }
                                }
                              }
                            });
                          } else {
                            // Open simple photo viewer
                            showDialog(
                              context: context,
                              builder: (ctx) => Dialog(
                                backgroundColor: Colors.transparent,
                                child: GlassContainer(
                                  borderRadius: 24,
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: hasHttp
                                            ? Image.network(
                                                photo.signedUrl,
                                                fit: BoxFit.contain,
                                                errorBuilder: (c, e, s) => const Center(
                                                  child: Icon(Icons.broken_image, size: 64),
                                                ),
                                              )
                                            : Image.file(
                                                File(photo.signedUrl),
                                                fit: BoxFit.contain,
                                                errorBuilder: (c, e, s) => const Center(
                                                  child: Icon(Icons.broken_image, size: 64),
                                                ),
                                              ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Logged: ${photo.createdAt.day}/${photo.createdAt.month}/${photo.createdAt.year}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          provider.deletePhoto(photo);
                                        },
                                        child: const Text('Delete Photo', style: TextStyle(color: Colors.redAccent)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: GlassContainer(
                                padding: EdgeInsets.zero,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: hasHttp
                                      ? Image.network(
                                          photo.signedUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (c, e, s) => const Center(
                                            child: Icon(Icons.broken_image, color: Colors.grey),
                                          ),
                                        )
                                      : Image.file(
                                          File(photo.signedUrl),
                                          fit: BoxFit.cover,
                                          errorBuilder: (c, e, s) => const Center(
                                            child: Icon(Icons.broken_image, color: Colors.grey),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(20),
                                    bottomRight: Radius.circular(20),
                                  ),
                                ),
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  '${photo.createdAt.day}/${photo.createdAt.month}/${photo.createdAt.year}',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            if (_compareMode)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isSelected ? theme.colorScheme.primary : Colors.black.withValues(alpha: 0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  child: Icon(
                                    isSelected ? Icons.check : Icons.add,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                    childCount: provider.photos.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      floatingActionButton: provider.isUploading
          ? const FloatingActionButton(
              onPressed: null,
              backgroundColor: AppColors.cardDarkGlass,
              child: CircularProgressIndicator(),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: GerexGradients.primaryCTA,
                borderRadius: BorderRadius.circular(16),
              ),
              child: FloatingActionButton(
                onPressed: () => _showImageSourceSelector(context, provider),
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: const FaIcon(FontAwesomeIcons.camera, color: Colors.white),
              ),
            ),
    );
  }
}
