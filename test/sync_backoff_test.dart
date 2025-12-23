import 'package:flutter_test/flutter_test.dart';
import 'package:nexus/core/utils/sync_backoff.dart';

void main() {
  test('computeBackoffSeconds grows exponentially and caps', () {
    expect(computeBackoffSeconds(0), 0);
    expect(computeBackoffSeconds(1), 1);
    expect(computeBackoffSeconds(2), 2);
    expect(computeBackoffSeconds(3), 4);
    expect(computeBackoffSeconds(4), 8);
    expect(computeBackoffSeconds(5), 16);
    expect(computeBackoffSeconds(6), 32);
    expect(computeBackoffSeconds(7), 32);
  });
}


