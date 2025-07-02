import 'package:flutter_test/flutter_test.dart';
import 'package:rem/firestore_service.dart';

void main() {
  test('circularDiffMinutes handles midnight wrap', () {
    final a = DateTime(2024, 1, 1, 23, 45);
    final b = DateTime(2024, 1, 2, 0, 15);
    expect(circularDiffMinutes(a, b), 30);
  });

  test('circularDiffMinutes basic difference', () {
    final a = DateTime(2024, 1, 1, 10, 0);
    final b = DateTime(2024, 1, 1, 11, 30);
    expect(circularDiffMinutes(a, b), 90);
  });
}
