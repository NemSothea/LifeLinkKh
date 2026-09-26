import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/src/core/location/geohash.dart';
import 'package:lifelink_kh/src/features/donor/domain/eligibility.dart';

/// The 56-day rule, ported from `EligibilityCalculator` (ADR 0009). The matching Function
/// has the same boundary tests — these two files are where the ports would drift.
void main() {
    final today = DateTime(2026, 9, 26);

    group('Eligibility.forLastDonation', () {
        test('never donated is eligible', () {
            expect(Eligibility.forLastDonation(null, today), const Eligibility(isEligible: true));
        });

        test('exactly 56 days ago is eligible — the boundary is inclusive', () {
            expect(Eligibility.forLastDonation(DateTime(2026, 8, 1), today).isEligible, isTrue);
        });

        test('55 days ago is one day short', () {
            expect(
                Eligibility.forLastDonation(DateTime(2026, 8, 2), today),
                Eligibility(isEligible: false, daysRemaining: 1, eligibleOn: DateTime(2026, 9, 27)),
            );
        });

        test('today is 56 days away', () {
            final result = Eligibility.forLastDonation(today, today);
            expect(result.daysRemaining, 56);
            expect(result.eligibleOn, DateTime(2026, 11, 21));
        });

        test('the time of day does not move the boundary', () {
            final lateNight = Eligibility.forLastDonation(DateTime(2026, 8, 1, 23, 59), DateTime(2026, 9, 26, 0, 1));
            expect(lateNight.isEligible, isTrue);
        });

        test('a daylight-saving-free count: across a month end and a year end', () {
            expect(Eligibility.forLastDonation(DateTime(2026, 12, 20), DateTime(2027, 2, 14)).isEligible, isTrue);
            expect(Eligibility.forLastDonation(DateTime(2026, 12, 20), DateTime(2027, 2, 13)).daysRemaining, 1);
        });
    });

    group('encodeGeohash', () {
        // Reference values from the geohash spec's own example and from geofire-common,
        // which the matching Function uses — the two must agree character for character.
        test('matches the reference encoder', () {
            expect(encodeGeohash(57.64911, 10.40744, precision: 11), 'u4pruydqqvj');
            expect(encodeGeohash(11.5806, 104.9165, precision: 5), 'w649g');
        });

        test("default precision is geofire-common's: 10 characters", () {
            expect(encodeGeohash(11.5806, 104.9165), 'w649gkjvgs');
        });
    });
}
