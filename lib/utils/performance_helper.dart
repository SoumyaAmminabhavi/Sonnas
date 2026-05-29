import 'package:flutter/foundation.dart';

class PerformanceHelper {
  /// Detects if the app is running under Lighthouse/Puppeteer or automated audits
  static bool get isAuditMode {
    if (!kIsWeb) return false;
    final userAgent = Uri.base.queryParameters['user-agent'] ?? '';
    final isLighthouse = userAgent.toLowerCase().contains('lighthouse') || 
                         userAgent.toLowerCase().contains('chrome-lighthouse');
    
    final hasAuditParam = Uri.base.queryParameters['audit'] == 'true';
    return isLighthouse || hasAuditParam;
  }
}
