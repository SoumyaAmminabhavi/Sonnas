enum StaffRole {
  manager,
  chef,
  support,
  cleaning,
  cashier,      // Future-proof
  delivery      // Future-proof
}

enum SubRole {
  headChef,
  assistantChef,
  cakeSpecialist,
  allRounder,
  none
}

enum StaffShift {
  morning,
  evening,
  fullDay
}

extension StaffRoleExtension on StaffRole {
  String get displayName {
    switch (this) {
      case StaffRole.manager: return "Manager";
      case StaffRole.chef: return "Kitchen / Production";
      case StaffRole.support: return "Support Staff";
      case StaffRole.cleaning: return "Cleaning & Maintenance";
      case StaffRole.cashier: return "Cashier";
      case StaffRole.delivery: return "Delivery Staff";
    }
  }

  String get dbValue => name.toUpperCase();
}

extension StaffShiftExtension on StaffShift {
  String get displayName {
    switch (this) {
      case StaffShift.morning: return "Morning Shift";
      case StaffShift.evening: return "Evening Shift";
      case StaffShift.fullDay: return "Full Day";
    }
  }
  String get dbValue => name.toUpperCase();
}

extension SubRoleExtension on SubRole {
  String get displayName {
    switch (this) {
      case SubRole.headChef: return "Head Chef";
      case SubRole.assistantChef: return "Assistant Chef";
      case SubRole.cakeSpecialist: return "Cakes & Fillings";
      case SubRole.allRounder: return "All-Rounder";
      case SubRole.none: return "General / None";
    }
  }
}
