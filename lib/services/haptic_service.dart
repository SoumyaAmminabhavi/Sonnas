import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class HapticService {
  static void light() {
    if (!kIsWeb) {
      HapticFeedback.lightImpact();
    }
  }

  static void selection() {
    if (!kIsWeb) {
      unawaited(HapticFeedback.selectionClick());
    }
  }

  static Future<void> success() async {
    if (!kIsWeb) {
      unawaited(HapticFeedback.mediumImpact());
    }
  }

  static void heavy() {
    if (!kIsWeb) {
      HapticFeedback.heavyImpact();
    }
  }
}
