import 'package:flutter_test/flutter_test.dart';
import 'package:vaccine_aapp/utils/date_utils.dart';

void main() {
  test('calculateAgeInMonths returns expected age', () {
    final age = calculateAgeInMonths(
      DateTime(2026, 1, 15),
      today: DateTime(2026, 4, 23),
    );

    expect(age, 3);
  });
}
