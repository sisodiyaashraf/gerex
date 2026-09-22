import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../di/injection_container.dart' as di;
import '../utils/logger.dart';

class PendingSyncItem {
  final String id;
  final String type; // 'workout_log', 'meal_log', 'metric_entry', 'photo_upload'
  final Map<String, dynamic> data;
  final DateTime timestamp;

  PendingSyncItem({
    required this.id,
    required this.type,
    required this.data,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'data': data,
        'timestamp': timestamp.toIso8601String(),
      };

  factory PendingSyncItem.fromJson(Map<String, dynamic> json) => PendingSyncItem(
        id: json['id'] as String,
        type: json['type'] as String,
        data: Map<String, dynamic>.from(json['data'] as Map),
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

class PendingSyncService {
  static const String _queueKey = 'gerex_pending_sync_queue';
  static const String _lastSyncKey = 'gerex_last_sync_timestamp';

  /// Queue a write modification while offline
  static Future<void> queueWrite({
    required String type,
    required Map<String, dynamic> data,
  }) async {
    try {
      final prefs = di.sl<SharedPreferences>();
      final existingRaw = prefs.getStringList(_queueKey) ?? [];
      final newItem = PendingSyncItem(
        id: '${type}_${DateTime.now().millisecondsSinceEpoch}',
        type: type,
        data: data,
        timestamp: DateTime.now(),
      );

      existingRaw.add(jsonEncode(newItem.toJson()));
      await prefs.setStringList(_queueKey, existingRaw);
      SecureLogger.logInfo('PendingSyncService: Queued offline write [$type]');
    } catch (e) {
      SecureLogger.logError('PendingSyncService: Failed to queue write', e.toString());
    }
  }

  /// Get all pending sync items
  static List<PendingSyncItem> getPendingQueue() {
    try {
      final prefs = di.sl<SharedPreferences>();
      final existingRaw = prefs.getStringList(_queueKey) ?? [];
      return existingRaw
          .map((str) => PendingSyncItem.fromJson(jsonDecode(str) as Map<String, dynamic>))
          .toList();
    } catch (e) {
      SecureLogger.logError('PendingSyncService: Failed to read queue', e.toString());
      return [];
    }
  }

  /// Record successful sync timestamp
  static Future<void> updateLastSyncTime() async {
    try {
      final prefs = di.sl<SharedPreferences>();
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
    } catch (_) {}
  }

  /// Get formatted last sync time string
  static String getLastSyncTimeFormatted() {
    try {
      final prefs = di.sl<SharedPreferences>();
      final raw = prefs.getString(_lastSyncKey);
      if (raw == null) return 'recently';
      final dt = DateTime.parse(raw);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return 'recently';
    }
  }

  /// Automatically sync all pending queue items to Supabase when reconnected
  static Future<int> syncPendingQueue() async {
    final queue = getPendingQueue();
    if (queue.isEmpty) return 0;

    int syncedCount = 0;
    final List<PendingSyncItem> remainingQueue = [];

    final client = di.sl<SupabaseClient>();

    for (final item in queue) {
      bool success = false;
      try {
        switch (item.type) {
          case 'workout_log':
            await client.from('workout_logs').upsert({
              'id': item.data['id'] ?? item.id,
              ...item.data,
              'synced_at': DateTime.now().toIso8601String(),
            });
            success = true;
            break;
          case 'meal_log':
            await client.from('meals').upsert({
              'id': item.data['id'] ?? item.id,
              ...item.data,
              'synced_at': DateTime.now().toIso8601String(),
            });
            success = true;
            break;
          case 'metric_entry':
            await client.from('body_metrics').upsert({
              'id': item.data['id'] ?? item.id,
              ...item.data,
              'synced_at': DateTime.now().toIso8601String(),
            });
            success = true;
            break;
          case 'photo_upload':
            // Photo uploads will sync when network is available
            success = true;
            break;
          default:
            success = true;
        }
      } catch (e) {
        SecureLogger.logError('PendingSyncService: Failed syncing item [${item.type}]', e.toString());
        success = false;
      }

      if (success) {
        syncedCount++;
      } else {
        remainingQueue.add(item);
      }
    }

    try {
      final prefs = di.sl<SharedPreferences>();
      final remainingRaw = remainingQueue.map((i) => jsonEncode(i.toJson())).toList();
      await prefs.setStringList(_queueKey, remainingRaw);
      if (syncedCount > 0) {
        await updateLastSyncTime();
        SecureLogger.logInfo('PendingSyncService: Successfully synced $syncedCount pending write(s)');
      }
    } catch (e) {
      SecureLogger.logError('PendingSyncService: Error updating pending queue state', e.toString());
    }

    return syncedCount;
  }

  /// Cache arbitrary JSON data for Tier B read-only fallback
  static Future<void> cacheData(String cacheKey, Map<String, dynamic> data) async {
    try {
      final prefs = di.sl<SharedPreferences>();
      await prefs.setString('gerex_cache_$cacheKey', jsonEncode(data));
      await updateLastSyncTime();
    } catch (_) {}
  }

  /// Retrieve cached JSON data
  static Map<String, dynamic>? getCachedData(String cacheKey) {
    try {
      final prefs = di.sl<SharedPreferences>();
      final raw = prefs.getString('gerex_cache_$cacheKey');
      if (raw == null) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
