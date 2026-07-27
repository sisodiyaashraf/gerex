import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/progress_photo.dart';
import 'package:gerex/core/providers/notification_provider.dart';
import 'package:gerex/core/utils/logger.dart';

class ProgressPhotosProvider extends ChangeNotifier {
  final SupabaseClient _supabase;
  final SharedPreferences _prefs;
  final NotificationProvider _notifications;
  final ImagePicker _picker = ImagePicker();

  ProgressPhotosProvider(this._supabase, this._prefs, this._notifications) {
    _loadLocalPhotos();
    _loadReminderSettings();
  }

  List<ProgressPhoto> _photos = [];
  List<ProgressPhoto> get photos => _photos;

  bool _isUploading = false;
  bool get isUploading => _isUploading;

  bool _remindersEnabled = true;
  bool get remindersEnabled => _remindersEnabled;

  String _reminderCadence = 'monthly'; // 'weekly' or 'monthly'
  String get reminderCadence => _reminderCadence;

  DateTime? _nextReminderDate;
  DateTime? get nextReminderDate => _nextReminderDate;

  // Load photos local cache
  void _loadLocalPhotos() {
    final list = _prefs.getStringList('cached_progress_photos') ?? [];
    try {
      _photos = list.map((item) {
        final parts = item.split(':::');
        return ProgressPhoto(
          id: parts[0],
          userId: parts[1],
          filePath: parts[2],
          signedUrl: parts.length > 3 ? parts[3] : '',
          createdAt: DateTime.tryParse(parts.length > 4 ? parts[4] : '') ?? DateTime.now(),
          pose: parts.length > 5 ? parts[5] : 'Front',
        );
      }).toList();
      _photos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      SecureLogger.logError('Failed to parse cached progress photos', e);
      _photos = [];
    }
    _calculateNextReminder();
    notifyListeners();
  }

  Future<void> _saveLocalPhotos() async {
    final list = _photos.map((p) => '${p.id}:::${p.userId}:::${p.filePath}:::${p.signedUrl}:::${p.createdAt.toIso8601String()}:::${p.pose}').toList();
    await _prefs.setStringList('cached_progress_photos', list);
  }

  void _loadReminderSettings() {
    _remindersEnabled = _prefs.getBool('progress_reminders_enabled') ?? true;
    _reminderCadence = _prefs.getString('progress_reminder_cadence') ?? 'monthly';
    _calculateNextReminder();
  }

  Future<void> setRemindersEnabled(bool enabled) async {
    _remindersEnabled = enabled;
    await _prefs.setBool('progress_reminders_enabled', enabled);
    _calculateNextReminder();
    notifyListeners();
  }

  Future<void> setReminderCadence(String cadence) async {
    _reminderCadence = cadence;
    await _prefs.setString('progress_reminder_cadence', cadence);
    _calculateNextReminder();
    notifyListeners();
  }

  void _calculateNextReminder() {
    if (!_remindersEnabled) {
      _nextReminderDate = null;
      return;
    }

    final latestDate = _photos.isNotEmpty ? _photos.first.createdAt : DateTime.now();
    if (_reminderCadence == 'weekly') {
      _nextReminderDate = latestDate.add(const Duration(days: 7));
    } else {
      // Monthly: add 30 days
      _nextReminderDate = latestDate.add(const Duration(days: 30));
    }
  }

  // Pick and upload progress photo
  Future<String?> addProgressPhoto(ImageSource source, {String pose = 'Front'}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1080,
      );
      if (image == null) return null;

      final file = File(image.path);

      // Validate size < 5MB
      final bytes = await file.length();
      if (bytes > 5 * 1024 * 1024) {
        return 'File is too large. Limit is 5MB.';
      }

      // Validate format
      final pathLower = image.path.toLowerCase();
      if (!pathLower.endsWith('.jpg') && !pathLower.endsWith('.jpeg') && !pathLower.endsWith('.png')) {
        return 'Unsupported format. Only JPG, JPEG, and PNG are allowed.';
      }

      _isUploading = true;
      notifyListeners();

      final user = _supabase.auth.currentUser;
      final userId = user?.id ?? 'guest_user';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'photo_$timestamp.jpg';
      final remotePath = '$userId/$fileName';

      String displayUrl = '';
      if (user != null) {
        // Real Supabase storage upload
        try {
          await _supabase.storage.from('progress-photos').upload(
            remotePath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

          // Get temporary signed URL (valid for 1 day)
          final signedUrlResponse = await _supabase.storage
              .from('progress-photos')
              .createSignedUrl(remotePath, 86400);
          displayUrl = signedUrlResponse;
        } catch (e) {
          SecureLogger.logError('Supabase upload failed, falling back to local file', e);
          displayUrl = image.path; // Fallback to path of picked file
        }
      } else {
        displayUrl = image.path; // Guest local storage path
      }

      final newPhoto = ProgressPhoto(
        id: timestamp.toString(),
        userId: userId,
        filePath: remotePath,
        signedUrl: displayUrl,
        createdAt: DateTime.now(),
        pose: pose,
      );

      _photos.insert(0, newPhoto);
      await _saveLocalPhotos();
      _calculateNextReminder();
      _isUploading = false;
      notifyListeners();

      // Trigger reminder check/alert
      await _notifications.sendNotification(
        'Progress Photo Added!',
        'Excellent consistency. Keep updating your photos regularly to track body changes.',
      );

      return null;
    } catch (e) {
      _isUploading = false;
      notifyListeners();
      SecureLogger.logError('Progress photo capture error', e);
      return 'An unexpected error occurred while capturing progress photo.';
    }
  }

  Future<String?> addCapturedPhoto(File file, String pose) async {
    try {
      final bytes = await file.length();
      if (bytes > 5 * 1024 * 1024) {
        return 'File is too large. Limit is 5MB.';
      }
      final pathLower = file.path.toLowerCase();
      if (!pathLower.endsWith('.jpg') && !pathLower.endsWith('.jpeg') && !pathLower.endsWith('.png')) {
        return 'Unsupported format. Only JPG, JPEG, and PNG are allowed.';
      }

      _isUploading = true;
      notifyListeners();

      final user = _supabase.auth.currentUser;
      final userId = user?.id ?? 'guest_user';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'photo_$timestamp.jpg';
      final remotePath = '$userId/$fileName';

      String displayUrl = '';
      if (user != null) {
        try {
          await _supabase.storage.from('progress-photos').upload(
            remotePath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );
          final signedUrlResponse = await _supabase.storage
              .from('progress-photos')
              .createSignedUrl(remotePath, 86400);
          displayUrl = signedUrlResponse;
        } catch (e) {
          SecureLogger.logError('Supabase upload failed, falling back to local file', e);
          displayUrl = file.path;
        }
      } else {
        displayUrl = file.path;
      }

      final newPhoto = ProgressPhoto(
        id: timestamp.toString(),
        userId: userId,
        filePath: remotePath,
        signedUrl: displayUrl,
        createdAt: DateTime.now(),
        pose: pose,
      );

      _photos.insert(0, newPhoto);
      await _saveLocalPhotos();
      _calculateNextReminder();
      _isUploading = false;
      notifyListeners();

      await _notifications.sendNotification(
        'Progress Photo Added!',
        'Excellent consistency. Keep updating your photos regularly to track body changes.',
      );

      return null;
    } catch (e) {
      _isUploading = false;
      notifyListeners();
      SecureLogger.logError('Progress photo capture error', e);
      return 'An unexpected error occurred while capturing progress photo.';
    }
  }

  Future<void> deletePhoto(ProgressPhoto photo) async {
    try {
      _photos.removeWhere((p) => p.id == photo.id);
      await _saveLocalPhotos();

      final user = _supabase.auth.currentUser;
      if (user != null && !photo.signedUrl.startsWith('http')) {
        // Attempt to clean storage bucket
        await _supabase.storage.from('progress-photos').remove([photo.filePath]);
      }
      _calculateNextReminder();
      notifyListeners();
    } catch (e) {
      SecureLogger.logError('Progress photo deletion error', e);
    }
  }
}
