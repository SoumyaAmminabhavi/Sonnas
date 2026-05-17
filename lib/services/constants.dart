class PriceConstants {
  static const int minorUnitsPerMajor = 100;
  static const String currencySymbol = '₹';
  static const String currencyCode = 'INR';
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
  static const double notificationDurationSeconds = 8;
  static const int pinCodeLength = 5;
  static const int minPasswordLength = 6;
}
