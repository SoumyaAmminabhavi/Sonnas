class PriceConstants {
  static const int minorUnitsPerMajor = 100;
  static const String currencySymbol = '₹';
  static const String currencyCode = 'INR';

  static double normalizePrice(dynamic rawPrice) {
    if (rawPrice == null) return 0.0;
    if (rawPrice is num) {
      return rawPrice.toDouble() / minorUnitsPerMajor;
    }
    
    final rawStr = rawPrice.toString().trim();
    if (rawStr.isEmpty) return 0.0;

    final upperStr = rawStr.toUpperCase();
    final hasCurrency = upperStr.contains('₹') || 
                        upperStr.contains('\$') || 
                        upperStr.contains('INR') || 
                        upperStr.contains('RS');
    final hasDecimal = rawStr.contains('.');
    final hasTrailing = rawStr.endsWith('/-');

    String clean = rawStr
        .replaceAll('₹', '')
        .replaceAll('\$', '')
        .replaceAll(RegExp(r'INR', caseSensitive: false), '')
        .replaceAll(RegExp(r'Rs\.?', caseSensitive: false), '')
        .replaceAll('/-', '')
        .replaceAll(',', '')
        .trim();
    
    final parsedVal = double.tryParse(clean) ?? 0.0;

    if (rawPrice is String && !hasCurrency && !hasDecimal && !hasTrailing) {
      return parsedVal;
    }

    if (hasCurrency || hasDecimal || hasTrailing) {
      return parsedVal;
    } else {
      return parsedVal / minorUnitsPerMajor.toDouble();
    }
  }
}

class AuthConstants {
  static const int maxOwnerPinAttempts = 3;
  static const Duration ownerPinLockoutDuration = Duration(minutes: 5);
  static const int maxStaffCodeAttempts = 5;
  static const Duration staffCodeLockoutDuration = Duration(minutes: 5);
  static const int phoneDigits = 10;
  static const String countryPrefix = '91';
  static const int maxImageSizeBytes = 5 * 1024 * 1024;
  static const int maxJoiningCodeRetries = 3;
}

class OrderConstants {
  static const int defaultOrderLimit = 100;
  static const int recentOrdersLimit = 50;
  static const int kitchenOrdersLimit = 50;
  static const Duration streamDebounce = Duration(milliseconds: 500);
  static const Duration orderHistoryWindow = Duration(days: 90);
  static const String defaultSource = 'APP';
}

class ReportConstants {
  static const int pdfRecentOrdersLimit = 20;
  static const int pdfExpenseEntriesLimit = 50;
}

class UiConstants {
  static const double desktopBreakpoint = 768;
  static const int notificationDurationSeconds = 8;
  static const int pinCodeLength = 5;
  static const int minPasswordLength = 6;
}
