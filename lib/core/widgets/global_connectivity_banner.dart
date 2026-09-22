import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connectivity_provider.dart';
import '../theme/app_theme.dart';

/// Global non-blocking persistent banner that appears at top of screen when offline
class GlobalConnectivityBanner extends StatelessWidget {
  final Widget child;

  const GlobalConnectivityBanner({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, conn, _) {
        final bool isOffline = conn.isOffline;
        final bool showRestored = conn.showRestoredBanner;

        return Stack(
          children: [
            // Main App Page Content
            child,

            // Top Persistent Non-Blocking Banner
            if (isOffline || showRestored)
              Positioned(
                top: MediaQuery.of(context).padding.top,
                left: 0,
                right: 0,
                child: SafeArea(
                  top: false,
                  child: IgnorePointer(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: showRestored
                            ? AppColors.accentEmeraldLight.withValues(alpha: 0.95)
                            : Colors.amber.shade900.withValues(alpha: 0.95),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black38,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            showRestored
                                ? Icons.wifi_rounded
                                : Icons.wifi_off_rounded,
                            color: showRestored ? Colors.black : Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            showRestored
                                ? "Back online — syncing data..."
                                : conn.pendingSyncCount > 0
                                    ? "You're offline — ${conn.pendingSyncCount} action(s) queued"
                                    : "You're offline — some features are limited",
                            style: TextStyle(
                              color: showRestored ? Colors.black : Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Offline indicator chip for Tier B screens rendering cached data
class OfflineCacheHeaderChip extends StatelessWidget {
  const OfflineCacheHeaderChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, conn, _) {
        if (conn.isOnline && conn.pendingSyncCount == 0) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.amber.shade900.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.amber.shade700.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                conn.isOffline ? Icons.history_rounded : Icons.sync_rounded,
                color: Colors.amber.shade300,
                size: 12,
              ),
              const SizedBox(width: 6),
              Text(
                conn.isOffline
                    ? 'Showing data from ${conn.lastSyncFormatted}'
                    : '${conn.pendingSyncCount} pending write(s)...',
                style: TextStyle(
                  color: Colors.amber.shade200,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
