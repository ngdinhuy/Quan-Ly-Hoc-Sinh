// Validation utilities for leave permission system

/// Validates CCCD (Citizen ID) format - must be exactly 12 digits
bool isValidCCCD(String cccd) {
  return RegExp(r'^\d{12}$').hasMatch(cccd);
}

/// Validates Vietnamese phone number format
/// Accepts formats: 0xxxxxxxxx or +84xxxxxxxxx
/// Valid prefixes after country code: 3, 5, 7, 8, 9
bool isValidVietnamesePhone(String phone) {
  return RegExp(r'^(0|\+84)(3|5|7|8|9)\d{8}$').hasMatch(phone);
}

/// Calculates the number of days between two dates (inclusive)
/// Returns 0 if return date is null or before leave date
int calculateMealDays(DateTime leave, DateTime? returnDate) {
  if (returnDate == null) return 0;

  final leaveOnly = DateTime(leave.year, leave.month, leave.day);
  final returnOnly = DateTime(
    returnDate.year,
    returnDate.month,
    returnDate.day,
  );

  if (returnOnly.isBefore(leaveOnly)) return 0;

  final difference = returnOnly.difference(leaveOnly).inDays;
  return difference + 1; // +1 to include both start and end dates
}

/// Generates a list of dates between leave date and return date (inclusive)
/// Returns empty list if return date is null or before leave date
/// All dates have time component set to midnight (date only)
List<DateTime> generateMealDeductionDates(
  DateTime leave,
  DateTime? returnDate,
) {
  if (returnDate == null) return [];

  final leaveOnly = DateTime(leave.year, leave.month, leave.day);
  final returnOnly = DateTime(
    returnDate.year,
    returnDate.month,
    returnDate.day,
  );

  if (returnOnly.isBefore(leaveOnly)) return [];

  List<DateTime> dates = [];
  DateTime current = leaveOnly;

  while (current.isBefore(returnOnly) || current.isAtSameMomentAs(returnOnly)) {
    dates.add(current);
    current = current.add(const Duration(days: 1));
  }

  return dates;
}

/// Validates that a date is within the leave period (inclusive)
/// Returns false if return date is null
bool isValidMealDeductionDate(
  DateTime date,
  DateTime leave,
  DateTime? returnDate,
) {
  if (returnDate == null) return false;

  final dateOnly = DateTime(date.year, date.month, date.day);
  final leaveOnly = DateTime(leave.year, leave.month, leave.day);
  final returnOnly = DateTime(
    returnDate.year,
    returnDate.month,
    returnDate.day,
  );

  return (dateOnly.isAfter(leaveOnly) ||
          dateOnly.isAtSameMomentAs(leaveOnly)) &&
      (dateOnly.isBefore(returnOnly) || dateOnly.isAtSameMomentAs(returnOnly));
}
