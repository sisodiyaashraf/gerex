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
    return const SizedBox.shrink();
  }
}
