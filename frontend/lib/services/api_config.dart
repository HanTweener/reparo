import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _configuredUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl {
    if (_configuredUrl.isNotEmpty) {
      return _configuredUrl;
    }
    if (kIsWeb) {
      final base = Uri.base;
      if (base.host == 'localhost' && base.port == 3000) {
        return 'http://localhost:8001/api/v1';
      }
      final origin = base.origin;
      if (origin.isNotEmpty && !origin.startsWith('file:')) {
        return '$origin/api/v1';
      }
    }
    return 'http://localhost:8001/api/v1';
  }
}

