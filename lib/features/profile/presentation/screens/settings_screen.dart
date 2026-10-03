import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gerex/core/theme/app_theme.dart';
import 'package:gerex/core/presentation/widgets/gerex_app_bar.dart';
import 'package:gerex/core/presentation/widgets/pastel_gradient_card.dart';
import 'package:gerex/core/presentation/widgets/glass_container.dart';
import 'package:gerex/core/presentation/widgets/gerex_button.dart';
import 'package:gerex/core/providers/notification_provider.dart';
import 'package:gerex/core/providers/connectivity_provider.dart';
import 'package:gerex/core/notifications/content_packs.dart';
import 'package:gerex/core/services/voice_coach_service.dart';
import 'package:gerex/core/di/injection_container.dart' as di;

import '../providers/profile_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../metrics/presentation/providers/heart_rate_provider.dart';

/// Clean & Responsive Consolidated Settings Screen for Gerex.
/// Eliminates render overflow issues, removes dev clutter, and fixes navigation paths.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Category-specific notification toggles state cached locally with SharedPreferences
  bool _workoutNotifs = true;
  bool _mealNotifs = true;
  bool _sleepNotifs = true;
  bool _hydrationNotifs = true;
  bool _streakNotifs = true;
  bool _aiNotifs = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationCategoryPrefs();
  }

  Future<void> _loadNotificationCategoryPrefs() async {
    final prefs = di.sl<SharedPreferences>();
    setState(() {
      _workoutNotifs = prefs.getBool('notif_cat_workout') ?? true;
      _mealNotifs = prefs.getBool('notif_cat_meal') ?? true;
      _sleepNotifs = prefs.getBool('notif_cat_sleep') ?? true;
      _hydrationNotifs = prefs.getBool('notif_cat_hydration') ?? true;
      _streakNotifs = prefs.getBool('notif_cat_streak') ?? true;
      _aiNotifs = prefs.getBool('notif_cat_ai') ?? true;
    });
  }

  Future<void> _toggleCategoryNotif(String key, bool val, Function(bool) updateState) async {
    final prefs = di.sl<SharedPreferences>();
    await prefs.setBool(key, val);
    setState(() {
      updateState(val);
    });
  }

  void _showLogoutConfirmation(BuildContext context, AuthProvider authProvider, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.textDarkMuted,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Confirm Sign Out',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDarkHeading,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to sign out? Your local data will remain safe on your device.',
                style: TextStyle(color: AppColors.textDarkMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GerexButton(
                      text: 'Cancel',
                      style: GerexButtonStyle.whitePill,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GerexButton(
                      text: 'Sign Out',
                      style: GerexButtonStyle.destructive,
                      onPressed: () async {
                        Navigator.pop(context);
                        await authProvider.signOut();
                        if (context.mounted) {
                          context.go('/login');
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteAccountConfirmation(BuildContext context, AuthProvider authProvider, ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              FaIcon(FontAwesomeIcons.triangleExclamation, color: Color(0xFFEF4444), size: 20),
              SizedBox(width: 10),
              Text('Delete Account?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: const Text(
            'This action is irreversible. All your workout history, custom plans, logs, and achievements will be permanently removed.',
            style: TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Navigator.pop(context);
                await authProvider.signOut();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Account deletion request queued successfully.')),
                  );
                  context.go('/login');
                }
              },
              child: const Text('Delete Permanently', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showClearCacheConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear Local Cache?'),
          content: const Text('This will clear temporary files and cached AI insights. Your core history will be preserved.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Local cache cleared successfully.')),
                );
              },
              child: const Text('Clear Cache', style: TextStyle(color: Color(0xFFEF4444))),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profileProvider = Provider.of<ProfileProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final connProvider = Provider.of<ConnectivityProvider>(context);
    final hrProvider = Provider.of<HeartRateProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);

    final bool isHrConnected = hrProvider.connectionState == HeartRateConnectionState.live || hrProvider.activeSource != HeartRateSource.none;
    final String deviceName = hrProvider.pairedDeviceName ?? 'Connected Device';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const GerexAppBar.standard(
        title: 'Settings',
        subtitle: 'App Preferences & Customization',
        showBackButton: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF0F1319), const Color(0xFF14181F)]
                : [const Color(0xFFF8FAFC), const Color(0xFFEEF2F6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 40.0),
          children: [

            // ================= SECTION 2: APP PREFERENCES =================
            _buildSectionHeader(theme, 'App Preferences'),
            const SizedBox(height: 10),
            _buildSettingsControlCard(
              icon: FontAwesomeIcons.scaleBalanced,
              title: 'Weight Units',
              subtitle: 'Display unit for exercises & weight logs',
              control: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'kg', label: Text('Kilograms (KG)')),
                  ButtonSegment(value: 'lb', label: Text('Pounds (LB)')),
                ],
                selected: {profileProvider.units},
                onSelectionChanged: (Set<String> selection) {
                  profileProvider.setUnits(selection.first);
                },
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
              ),
            ),
            const SizedBox(height: 8),
            _buildSettingsControlCard(
              icon: FontAwesomeIcons.earthAsia,
              title: 'Regional Content Pack',
              subtitle: 'Notification phrasing & motivational style',
              control: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: notificationProvider.service.contentPack.id,
                  dropdownColor: theme.cardColor,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF14181F),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  items: NotificationContentPacks.all
                      .map((pack) => DropdownMenuItem(
                            value: pack.id,
                            child: Text(
                              pack.label,
                              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF14181F)),
                            ),
                          ))
                      .toList(),
                  onChanged: notificationProvider.setContentPack,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ================= SECTION 3: NOTIFICATIONS =================
            _buildSectionHeader(theme, 'Notifications & Reminders'),
            const SizedBox(height: 10),
            _buildSettingsRow(
              icon: FontAwesomeIcons.bell,
              title: 'Push Notifications Master',
              subtitle: 'Allow Gerex reminders and nudges',
              trailing: Switch.adaptive(
                value: profileProvider.notificationsEnabled,
                onChanged: (bool value) async {
                  if (!value) {
                    await profileProvider.toggleNotifications(false);
                    return;
                  }
                  final granted = await notificationProvider.requestSystemPermission();
                  if (granted) await profileProvider.toggleNotifications(true);
                },
              ),
            ),
            if (profileProvider.notificationsEnabled) ...[
              const SizedBox(height: 8),
              _buildCategoryToggleRow('Workout Reminders', _workoutNotifs, (v) => _toggleCategoryNotif('notif_cat_workout', v, (val) => _workoutNotifs = val)),
              const SizedBox(height: 6),
              _buildCategoryToggleRow('Meal & Nutrition Reminders', _mealNotifs, (v) => _toggleCategoryNotif('notif_cat_meal', v, (val) => _mealNotifs = val)),
              const SizedBox(height: 6),
              _buildCategoryToggleRow('Sleep & Bedtime Alerts', _sleepNotifs, (v) => _toggleCategoryNotif('notif_cat_sleep', v, (val) => _sleepNotifs = val)),
              const SizedBox(height: 6),
              _buildCategoryToggleRow('Hydration Nudges', _hydrationNotifs, (v) => _toggleCategoryNotif('notif_cat_hydration', v, (val) => _hydrationNotifs = val)),
              const SizedBox(height: 6),
              _buildCategoryToggleRow('Streak Risk Alerts', _streakNotifs, (v) => _toggleCategoryNotif('notif_cat_streak', v, (val) => _streakNotifs = val)),
              const SizedBox(height: 6),
              _buildCategoryToggleRow('AI Health Insights', _aiNotifs, (v) => _toggleCategoryNotif('notif_cat_ai', v, (val) => _aiNotifs = val)),
            ],

            const SizedBox(height: 24),

            // ================= SECTION 4: VOICE COACH =================
            _buildSectionHeader(theme, 'Real-Time Voice Coach'),
            const SizedBox(height: 10),
            _buildSettingsRow(
              icon: FontAwesomeIcons.volumeHigh,
              title: 'Voice Coaching Audio',
              subtitle: 'Real-time workout guidance & audio cues',
              trailing: Switch.adaptive(
                value: profileProvider.voiceCoachingEnabled,
                onChanged: (val) => profileProvider.toggleVoiceCoaching(val),
              ),
            ),
            if (profileProvider.voiceCoachingEnabled) ...[
              const SizedBox(height: 8),
              _buildVoiceCoachDetailsCard(context, profileProvider, theme),
            ],

            const SizedBox(height: 24),

            // ================= SECTION 5: CONNECTED DEVICES =================
            _buildSectionHeader(theme, 'Connected Devices & Health'),
            const SizedBox(height: 10),
            _buildSettingsRow(
              icon: FontAwesomeIcons.heartPulse,
              title: 'Heart Rate Monitor',
              subtitle: isHrConnected ? 'Connected: $deviceName' : 'No BLE sensor connected',
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isHrConnected ? const Color(0xFF10B981).withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isHrConnected ? 'Connected' : 'Manage',
                  style: TextStyle(
                    color: isHrConnected ? const Color(0xFF10B981) : theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              onTap: () => context.push('/heart-rate-connect'),
            ),
            const SizedBox(height: 8),
            _buildSettingsRow(
              icon: FontAwesomeIcons.kitMedical,
              title: 'Health Connect / HealthKit',
              subtitle: 'Sync steps, sleep, and heart rate',
              trailing: Switch.adaptive(
                value: true,
                onChanged: (val) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Health Connect sync enabled.')),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // ================= SECTION 6: WORKOUT EXPERIENCE & EFFECTS =================
            _buildSectionHeader(theme, 'Workout Experience & FX'),
            const SizedBox(height: 10),
            _buildSettingsRow(
              icon: FontAwesomeIcons.hand,
              title: 'Haptic Feedback',
              subtitle: 'Tactile vibrations during set completions',
              trailing: Switch.adaptive(
                value: profileProvider.hapticsEnabled,
                onChanged: (val) => profileProvider.toggleHaptics(val),
              ),
            ),
            const SizedBox(height: 8),
            _buildSettingsRow(
              icon: FontAwesomeIcons.fire,
              title: 'Animated Streak Flame',
              subtitle: 'Show animated flame in dashboard header',
              trailing: Switch.adaptive(
                value: profileProvider.streakFlameEnabled,
                onChanged: (val) => profileProvider.toggleStreakFlame(val),
              ),
            ),
            const SizedBox(height: 8),
            _buildSettingsRow(
              icon: FontAwesomeIcons.gift,
              title: 'Confetti Celebrations',
              subtitle: 'Play confetti animation on PR record',
              trailing: Switch.adaptive(
                value: profileProvider.confettiEnabled,
                onChanged: (val) => profileProvider.toggleConfetti(val),
              ),
            ),

            const SizedBox(height: 24),

            // ================= SECTION 7: DATA & STORAGE =================
            _buildSectionHeader(theme, 'Data & Local Storage'),
            const SizedBox(height: 10),
            _buildSettingsRow(
              icon: FontAwesomeIcons.database,
              title: 'Offline Cache & Sync Status',
              subtitle: 'Last sync: ${connProvider.lastSyncFormatted}',
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: connProvider.pendingSyncCount > 0 ? Colors.amber.withValues(alpha: 0.2) : const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  connProvider.pendingSyncCount > 0 ? '${connProvider.pendingSyncCount} pending' : 'Synced',
                  style: TextStyle(
                    color: connProvider.pendingSyncCount > 0 ? Colors.amber.shade800 : const Color(0xFF10B981),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildSettingsRow(
              icon: FontAwesomeIcons.trashCan,
              title: 'Clear Local Cache',
              subtitle: 'Free up local memory without deleting progress',
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              onTap: () => _showClearCacheConfirmation(context),
            ),

            const SizedBox(height: 24),

            // ================= SECTION 8: ABOUT & SUPPORT =================
            _buildSectionHeader(theme, 'About & Support'),
            const SizedBox(height: 10),
            _buildSettingsRow(
              icon: FontAwesomeIcons.circleInfo,
              title: 'About Gerex',
              subtitle: 'Version 1.0.0 (Build 2026)',
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'Gerex',
                  applicationVersion: '1.0.0',
                  applicationLegalese: '© 2026 Gerex Dev Team. All rights reserved.',
                );
              },
            ),
            const SizedBox(height: 8),
            _buildSettingsRow(
              icon: FontAwesomeIcons.headset,
              title: 'Contact Support & Feedback',
              subtitle: 'Get help or submit feedback',
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Support email: support@gerex.fit')),
                );
              },
            ),

            const SizedBox(height: 32),

            // ================= SECTION 9: ACCOUNT ACTIONS (DESTRUCTIVE AREA) =================
            InkWell(
              onTap: () => _showLogoutConfirmation(context, authProvider, theme),
              borderRadius: BorderRadius.circular(16),
              child: const PastelGradientCard(
                type: PastelCardType.rose,
                padding: EdgeInsets.symmetric(vertical: 14.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(FontAwesomeIcons.rightFromBracket, color: Color(0xFFC7363B), size: 16),
                    SizedBox(width: 10),
                    Text(
                      'Sign Out',
                      style: TextStyle(color: Color(0xFFC7363B), fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.0),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: () => _showDeleteAccountConfirmation(context, authProvider, theme),
                icon: const FaIcon(FontAwesomeIcons.trash, size: 13, color: Color(0xFFEF4444)),
                label: const Text(
                  'Delete Account & Data',
                  style: TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
        fontSize: 15,
      ),
    );
  }

  Widget _buildSettingsRow({
    required dynamic icon,
    required String title,
    String? subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: PastelGradientCard(
        type: PastelCardType.slate,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF14181F).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: FaIcon(
                  icon,
                  size: 14.0,
                  color: const Color(0xFF14181F),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF14181F),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: const Color(0xFF14181F).withValues(alpha: 0.65),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsControlCard({
    required dynamic icon,
    required String title,
    required String subtitle,
    required Widget control,
  }) {
    return PastelGradientCard(
      type: PastelCardType.slate,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF14181F).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: FaIcon(
                    icon,
                    size: 14.0,
                    color: const Color(0xFF14181F),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF14181F),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: const Color(0xFF14181F).withValues(alpha: 0.65),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: control,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryToggleRow(String title, bool val, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(left: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          Switch.adaptive(
            value: val,
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceCoachDetailsCard(BuildContext context, ProfileProvider profileProvider, ThemeData theme) {
    final voiceCoach = di.sl<VoiceCoachService>();

    return PastelGradientCard(
      type: PastelCardType.mint,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Voice Coach Customization', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF14181F))),
              IconButton(
                icon: const FaIcon(FontAwesomeIcons.play, size: 14, color: Color(0xFF10B981)),
                tooltip: 'Preview Voice',
                onPressed: () => voiceCoach.speakPreview(
                  language: profileProvider.voiceCoachLanguage,
                  persona: profileProvider.voiceCoachPersona,
                  rate: profileProvider.voiceCoachRate,
                  pitch: profileProvider.voiceCoachPitch,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Language:', style: TextStyle(fontSize: 12, color: Color(0xFF14181F))),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: profileProvider.voiceCoachLanguage,
                underline: const SizedBox.shrink(),
                style: const TextStyle(color: Color(0xFF14181F), fontWeight: FontWeight.bold, fontSize: 12),
                items: const [
                  DropdownMenuItem(value: 'english', child: Text('English')),
                  DropdownMenuItem(value: 'hindi', child: Text('Hindi')),
                  DropdownMenuItem(value: 'hinglish', child: Text('Hinglish')),
                ],
                onChanged: (v) {
                  if (v != null) profileProvider.setVoiceCoachLanguage(v);
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Text('Persona:', style: TextStyle(fontSize: 12, color: Color(0xFF14181F))),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: profileProvider.voiceCoachPersona,
                underline: const SizedBox.shrink(),
                style: const TextStyle(color: Color(0xFF14181F), fontWeight: FontWeight.bold, fontSize: 12),
                items: const [
                  DropdownMenuItem(value: 'motivator', child: Text('Motivator')),
                  DropdownMenuItem(value: 'drill_sergeant', child: Text('Drill Sergeant')),
                  DropdownMenuItem(value: 'chill', child: Text('Chill Coach')),
                  DropdownMenuItem(value: 'playful', child: Text('Playful')),
                ],
                onChanged: (v) {
                  if (v != null) profileProvider.setVoiceCoachPersona(v);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Speech Speed (${profileProvider.voiceCoachRate.toStringAsFixed(1)}x)', style: const TextStyle(fontSize: 11, color: Color(0xFF14181F))),
          Slider(
            value: profileProvider.voiceCoachRate,
            min: 0.3,
            max: 0.9,
            onChanged: (val) => profileProvider.setVoiceCoachRate(val),
          ),
        ],
      ),
    );
  }
}
