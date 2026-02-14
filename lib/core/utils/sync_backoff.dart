import 'dart:math';

/// Exponential backoff seconds for retries.
/// retryCount: 1 => 1s, 2 => 2s, 3 => 4s, ... capped at 32s (retry 6).
int computeBackoffSeconds(int retryCount) {
  if (retryCount <= 0) return 0;
  final exp = max(0, retryCount - 1);
  return min(32, pow(2, exp).toInt());
}
