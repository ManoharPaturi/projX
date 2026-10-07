import 'package:omr_core/omr_core.dart';
import 'package:test/test.dart';

void main() {
  group('canonicalRoll', () {
    test('numeric rolls compare by value', () {
      expect(canonicalRoll('0001234'), '1234');
      expect(canonicalRoll(' 1234 '), '1234');
      expect(canonicalRoll('0000000'), '0');
    });

    test('alphanumeric rolls compare trimmed and case-folded', () {
      expect(canonicalRoll(' r001 '), 'R001');
    });
  });

  group('isScannableRoll', () {
    test('digits within the column count are scannable', () {
      expect(isScannableRoll('1234'), isTrue);
      expect(isScannableRoll('0001234'), isTrue);
      expect(isScannableRoll('9999999'), isTrue);
    });

    test('letters, blanks and overlong rolls are not', () {
      expect(isScannableRoll('R001'), isFalse);
      expect(isScannableRoll(''), isFalse);
      expect(isScannableRoll('12345678'), isFalse);
      // Leading zeros beyond the columns are harmless: value fits.
      expect(isScannableRoll('00001234'), isTrue);
    });
  });

  group('rollCheckDigit', () {
    test('matches the weighted checksum over the right-aligned payload', () {
      // 0001234 → 0·3+0·1+0·3+1·1+2·3+3·1+4·3 = 22 → 2
      expect(rollCheckDigit('1234'), 2);
      expect(rollCheckDigit('0001234'), 2);
      expect(rollChecksumOf([0, 0, 0, 1, 2, 3, 4]), 2);
    });

    test('detects an adjacent transposition', () {
      expect(rollCheckDigit('1243'), isNot(rollCheckDigit('1234')));
    });

    test('is null for rolls that cannot be bubbled', () {
      expect(rollCheckDigit('R001'), isNull);
      expect(rollCheckDigit('12345678'), isNull);
    });
  });
}
