import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/heart_rate_provider.dart';
import 'package:gerex/core/providers/activity_provider.dart';
import 'package:gerex/core/presentation/widgets/glass_container.dart';
import 'package:gerex/core/presentation/widgets/pastel_gradient_card.dart';
import 'package:gerex/core/presentation/widgets/gerex_scaffold.dart';
import 'package:gerex/core/theme/app_theme.dart';

class HeartRateConnectionScreen extends StatelessWidget {
  const HeartRateConnectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hrProvider = Provider.of<HeartRateProvider>(context);
    final activityProvider = Provider.of<ActivityProvider>(context, listen: false);

    return GerexScaffold(
      appBar: AppBar(
        title: Text(
          'Heart Rate Monitor',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textDarkHeading,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDarkHeading),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Smartwatch expectations notice
                _buildDisclaimerCard(theme),
                const SizedBox(height: 20),

                // Current Active Device Card
                _buildActiveConnectionCard(context, theme, hrProvider),
                const SizedBox(height: 20),

                // Platform Health Path (Health Connect / HealthKit)
                _buildHealthPlatformCard(context, theme, hrProvider, activityProvider),
                const SizedBox(height: 20),

                // Direct BLE Connection Path
                _buildBleScannerCard(context, theme, hrProvider),
                const SizedBox(height: 20),

                // Manual Log Fallback Card
                _ManualLogCard(provider: hrProvider),
                const SizedBox(height: 20),

                // Developer Simulator Mode Card
                _buildSimulatorCard(context, theme, hrProvider),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveConnectionCard(
    BuildContext context,
    ThemeData theme,
    HeartRateProvider provider,
  ) {
    final isConnected = provider.connectionState == HeartRateConnectionState.live;
    final deviceName = provider.pairedDeviceName ?? 'No monitor connected';
    final activeBpm = provider.currentBpm;
    
    Color badgeColor = Colors.grey.shade700;
    Color badgeText = Colors.white70;
    String badgeLabel = 'Inactive';
    IconData statusIcon = Icons.sensors_off_rounded;

    if (isConnected) {
      badgeColor = AppColors.accentEmeraldLight.withValues(alpha: 0.2);
      badgeText = AppColors.accentEmeraldLight;
      badgeLabel = 'Connected';
      statusIcon = Icons.sensors_rounded;
    } else if (provider.connectionState == HeartRateConnectionState.disconnected) {
      badgeColor = Colors.redAccent.withValues(alpha: 0.2);
      badgeText = Colors.redAccent;
      badgeLabel = 'Disconnected';
      statusIcon = Icons.signal_wifi_bad_rounded;
    }

    return PastelGradientCard(
      type: PastelCardType.rose,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ACTIVE SENSOR STATUS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF14181F).withValues(alpha: 0.6),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: badgeText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: isConnected ? Colors.pink.shade50 : Colors.grey.shade200,
                radius: 24,
                child: Icon(
                  statusIcon,
                  color: isConnected ? Colors.pink : Colors.grey.shade600,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deviceName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF14181F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isConnected 
                          ? 'Source: ${provider.activeSource.name.toUpperCase()}'
                          : 'Pair a device or enable health sync below',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF14181F).withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (isConnected) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      activeBpm != null ? '$activeBpm' : '--',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Outfit',
                        color: Color(0xFF14181F),
                      ),
                    ),
                    const Text(
                      'BPM',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF14181F),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          if (isConnected) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white24,
                  foregroundColor: Colors.pink.shade800,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('Disconnect Device'),
                onPressed: () => provider.disconnectBleDevice(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHealthPlatformCard(
    BuildContext context,
    ThemeData theme,
    HeartRateProvider provider,
    ActivityProvider activityProvider,
  ) {
    final isHealthActive = provider.connectionState == HeartRateConnectionState.live &&
        provider.activeSource == HeartRateSource.health;

    return GlassContainer(
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(
                FontAwesomeIcons.heartPulse,
                color: Colors.redAccent.shade200,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'OS Health Platform Sync',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Sync heart rate automatically if your smartwatch companion app (such as FitCloudPro, Zepp, Samsung Health, Fitbit, or Apple Health) is configured to write data to Android Health Connect or iOS HealthKit.',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          if (provider.hadEmptyHealthResponse) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'No heart rate data found in Health Connect',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check your smartwatch app settings (like FitCloudPro, Samsung Health, etc.) to ensure it is syncing heart rate data to Health Connect, then tap Recheck below.',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.4,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.amber),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.amber),
                      label: const Text('Recheck Now', style: TextStyle(color: Colors.amber, fontSize: 12)),
                      onPressed: () async {
                        await provider.fetchLatestHealthReading();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (provider.healthConnectError != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          provider.healthConnectError!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                   if (!provider.isHealthConnectInstalled) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 36,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.download_rounded, size: 16),
                        label: const Text('Install Health Connect', style: TextStyle(fontSize: 12)),
                        onPressed: () async {
                          await provider.installHealthConnect();
                        },
                      ),
                    ),
                  ] else if (provider.isHealthConnectDeniedPermanently) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 36,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.settings_suggest_rounded, size: 16),
                        label: const Text('Manage Settings in Health Connect', style: TextStyle(fontSize: 12)),
                        onPressed: () async {
                          await provider.openHealthConnectPermissions();
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isHealthActive 
                    ? AppColors.accentEmeraldLight.withValues(alpha: 0.2)
                    : theme.colorScheme.primary,
                foregroundColor: isHealthActive 
                    ? AppColors.accentEmeraldLight
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(
                isHealthActive ? Icons.check_circle_rounded : Icons.sync_rounded,
                size: 16,
              ),
              label: Text(
                isHealthActive ? 'Active OS Syncing' : 'Enable OS Health Sync',
              ),
              onPressed: isHealthActive 
                  ? null 
                  : () async {
                      final hasPerm = await provider.requestHealthPermissions();
                      if (hasPerm) {
                        await provider.startHealthConnectPolling(activityProvider: activityProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('OS Health Platform synchronization enabled!')),
                          );
                        }
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to get health permissions. Confirm Health Connect is installed and permitted.'),
                            ),
                          );
                        }
                      }
                    },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBleScannerCard(
    BuildContext context,
    ThemeData theme,
    HeartRateProvider provider,
  ) {
    return GlassContainer(
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.bluetooth,
                color: Colors.blueAccent,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Direct Bluetooth Sensors',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Connect directly to standalone chest straps, arm bands, or sports sensors broadcasting standard Bluetooth Heart Rate signals (GATT Profile 0x180D). Proprietary smartwatch companion apps are not supported via direct BLE scan.',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: provider.isScanning
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent),
                        )
                      : const Icon(Icons.search_rounded, size: 16),
                  label: Text(provider.isScanning ? 'Scanning...' : 'Scan Bluetooth'),
                  onPressed: provider.isScanning 
                      ? () => provider.stopBleScan()
                      : () => provider.startBleScan(),
                ),
              ),
            ],
          ),
          if (provider.bleConnectionError != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      provider.bleConnectionError!,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (provider.discoveredDevices.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Discovered Devices',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.discoveredDevices.length,
              itemBuilder: (context, index) {
                final result = provider.discoveredDevices[index];
                final devName = result.device.platformName.isNotEmpty 
                    ? result.device.platformName 
                    : 'Unknown HR Sensor';
                final isConnecting = provider.connectionState == HeartRateConnectionState.connect &&
                    provider.pairedDeviceMac == result.device.remoteId.toString();

                return Card(
                  color: theme.colorScheme.surface.withValues(alpha: 0.05),
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                      child: Icon(Icons.bluetooth_audio_rounded, color: theme.colorScheme.primary, size: 18),
                    ),
                    title: Text(
                      devName,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'MAC: ${result.device.remoteId} • RSSI: ${result.rssi} dBm',
                      style: const TextStyle(fontSize: 10),
                    ),
                    trailing: isConnecting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () => provider.connectToBleDevice(result.device),
                            child: const Text('Connect', style: TextStyle(fontSize: 11)),
                          ),
                  ),
                );
              },
            ),
          ] else if (provider.isScanning) ...[
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'Searching for Heart Rate monitors...',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSimulatorCard(
    BuildContext context,
    ThemeData theme,
    HeartRateProvider provider,
  ) {
    final isSimulating = provider.connectionState == HeartRateConnectionState.live &&
        provider.activeSource == HeartRateSource.simulator;

    return PastelGradientCard(
      type: PastelCardType.slate,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.developer_mode_rounded,
                color: Colors.amber,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Developer HR Simulator',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF14181F),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Simulate live heart rate updates immediately. Best for dashboard visual testing, mock layouts validation, or local emulator runs.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF14181F),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isSimulating ? Colors.amber.shade200 : Colors.white30,
                foregroundColor: const Color(0xFF14181F),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(
                isSimulating ? Icons.bolt_rounded : Icons.play_arrow_rounded,
                color: const Color(0xFF14181F),
                size: 16,
              ),
              label: Text(
                isSimulating ? 'Simulation Active' : 'Start Simulation Feed',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: isSimulating 
                  ? null 
                  : () {
                      provider.startSimulatorFeed();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Developer mock Heart Rate simulator started!')),
                      );
                    },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimerCard(ThemeData theme) {
    return GlassContainer(
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: Colors.amberAccent,
                size: 20,
              ),
              SizedBox(width: 12),
              Text(
                'Smartwatch Compatibility Notice',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Gerex works with any watch whose app (such as FitCloudPro, Zepp, Samsung Health, or Fitbit) syncs data to Apple Health (iOS) or Health Connect (Android), or any chest strap/monitor broadcasting a standard Bluetooth heart rate signal. Proprietary smartwatch apps do not support direct Bluetooth pairing inside third-party apps like Gerex.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManualLogCard extends StatefulWidget {
  final HeartRateProvider provider;

  const _ManualLogCard({required this.provider});

  @override
  State<_ManualLogCard> createState() => _ManualLogCardState();
}

class _ManualLogCardState extends State<_ManualLogCard> {
  final _formKey = GlobalKey<FormState>();
  final _bpmController = TextEditingController();

  @override
  void dispose() {
    _bpmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassContainer(
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.edit_note_rounded,
                  color: Colors.pinkAccent,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Manual Log Fallback',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'If your watch app does not sync automatically, read the BPM from your watch face and log it manually here.',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _bpmController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'e.g. 72',
                      labelText: 'Heart Rate (BPM)',
                      labelStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 18),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'BPM is required';
                      }
                      final numVal = int.tryParse(val);
                      if (numVal == null) {
                        return 'Enter a valid number';
                      }
                      if (numVal < 30 || numVal > 220) {
                        return 'Enter value between 30 and 220';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final bpm = int.parse(_bpmController.text);
                        final error = await widget.provider.logManualBpm(bpm);
                        if (context.mounted) {
                          if (error != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error)),
                            );
                          } else {
                            _bpmController.clear();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Manually logged heart rate: $bpm BPM')),
                            );
                          }
                        }
                      }
                    },
                    child: const Text('Log BPM'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
