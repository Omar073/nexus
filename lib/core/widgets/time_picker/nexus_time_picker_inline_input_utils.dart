bool shouldAutoCommitHourInput({
  required bool use24Hour,
  required String rawValue,
}) {
  final trimmed = rawValue.trim();
  if (trimmed.isEmpty) return false;

  final parsed = int.tryParse(trimmed);
  if (parsed == null) return false;

  final length = trimmed.length;
  if (use24Hour) {
    // In 24h mode: 0/1/2 may be first digit of a 2-digit hour (00-23),
    // while 3-9 are complete single-digit hours.
    return length >= 2 || parsed >= 3;
  }

  // In 12h mode: 1 can become 10/11/12, so wait for optional second digit.
  // 2-9 are complete single-digit hours.
  return length >= 2 || parsed >= 2;
}
