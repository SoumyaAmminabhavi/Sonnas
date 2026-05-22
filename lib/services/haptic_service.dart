import 'package:flutter/services.dart';

class HapticService {
  static void light() {
    HapticFeedback.lightImpact();
  }

  static void selection() {
    HapticFeedback.selectionClick();
  }

  static void medium() {
    HapticFeedback.mediumImpact();
  }

  static void success() {
    HapticFeedback.mediumImpact();
  }
}
