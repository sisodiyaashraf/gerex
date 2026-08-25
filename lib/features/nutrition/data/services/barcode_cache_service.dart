import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BarcodeCacheService {
  final SharedPreferences _prefs;

  BarcodeCacheService(this._prefs);

  Future<void> cacheProduct(String barcode, Map<String, dynamic> productData) async {
    await _prefs.setString('barcode_cache_$barcode', json.encode(productData));
  }

  Map<String, dynamic>? getCachedProduct(String barcode) {
    final dataStr = _prefs.getString('barcode_cache_$barcode');
    if (dataStr == null) return null;
    try {
      return json.decode(dataStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
