/// Formats a recent date into a small, localized relative string.
///
/// Story 8.4 keeps this helper dependency-light and testable while still
/// respecting the current locale for English and French.
String formatRelativeDate(
  DateTime date, {
  DateTime? now,
  String languageCode = 'en',
}) {
  final reference = now ?? DateTime.now();
  final normalizedReference = DateTime(
    reference.year,
    reference.month,
    reference.day,
  );
  final normalizedDate = DateTime(date.year, date.month, date.day);
  final days = normalizedReference.difference(normalizedDate).inDays;

  if (languageCode == 'fr') {
    return _formatRelativeDateFr(days);
  }

  return _formatRelativeDateEn(days);
}

String _formatRelativeDateEn(int days) {
  if (days < 0) {
    final futureDays = days.abs();
    if (futureDays == 1) return 'Tomorrow';
    return 'In $futureDays days';
  }
  if (days == 0) return 'Today';
  if (days == 1) return 'Yesterday';
  if (days < 7) return '$days days ago';

  final weeks = days ~/ 7;
  if (weeks == 1) return '1 week ago';
  if (days < 30) return '$weeks weeks ago';

  final months = days ~/ 30;
  if (months == 1) return '1 month ago';
  if (days < 365) return '$months months ago';

  final years = days ~/ 365;
  if (years == 1) return '1 year ago';
  return '$years years ago';
}

String _formatRelativeDateFr(int days) {
  if (days < 0) {
    final futureDays = days.abs();
    if (futureDays == 1) return 'Demain';
    return 'Dans $futureDays jours';
  }
  if (days == 0) return "Aujourd'hui";
  if (days == 1) return 'Hier';
  if (days < 7) return 'Il y a $days jours';

  final weeks = days ~/ 7;
  if (weeks == 1) return 'Il y a 1 semaine';
  if (days < 30) return 'Il y a $weeks semaines';

  final months = days ~/ 30;
  if (months == 1) return 'Il y a 1 mois';
  if (days < 365) return 'Il y a $months mois';

  final years = days ~/ 365;
  if (years == 1) return 'Il y a 1 an';
  return 'Il y a $years ans';
}
