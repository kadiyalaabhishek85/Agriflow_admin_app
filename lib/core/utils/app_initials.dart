/// Single source of truth for avatar initials (flutter-03 rec 11: replaces
/// the seven per-feature copies in farmer/manager/farm-visit/grain/billing
/// entities and the booking/seed-purchase cards).
///
/// Rules (unified from the previous variants):
/// - Non-alphabetic characters are stripped before splitting into words.
/// - Two or more words → first letters of the first two words.
/// - One word → its first letter.
/// - All upper case; empty/whitespace-only input → [fallback].
abstract class AppInitials {
  static String of(String? name, {String fallback = 'F'}) {
    if (name == null || name.trim().isEmpty) return fallback;
    final clean = name.replaceAll(RegExp(r'[^a-zA-Z\s]'), ' ').trim();
    if (clean.isEmpty) return fallback;
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[1].isNotEmpty) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}
