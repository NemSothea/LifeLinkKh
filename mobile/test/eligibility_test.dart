import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/src/core/location/geohash.dart';
import 'package:lifelink_kh/src/features/donor/domain/donor_sex.dart';
import 'package:lifelink_kh/src/features/donor/domain/eligibility.dart';

/// The donation interval: 90 days for men, 120 for women (DEC-019). The portal's matching
/// (`frontend/test/server/unit/matching.test.js`) has the same boundary tests — these two
/// files are where the two implementations would drift.
void main() {
    final today = DateTime(2026, 9, 26);

    group('Eligibility.forLastDonation', () {
        test('never donated is eligible', () {
            expect(Eligibility.forLastDonation(null, today), const Eligibility(isEligible: true));
        });

        // DEC-019: 90 days for men, 120 for women, 120 when the donor prefers not to say.
        test('the intervals: 90 days for men, 120 for women and for not given', () {
            expect(Eligibility.cooldownDaysFor(DonorSex.male), 90);
            expect(Eligibility.cooldownDaysFor(DonorSex.female), 120);
            expect(Eligibility.cooldownDaysFor(null), 120);
        });

        test('a man exactly 90 days after donating is eligible — the boundary is inclusive', () {
            expect(Eligibility.forLastDonation(DateTime(2026, 6, 28), today, sex: DonorSex.male).isEligible, isTrue);
        });

        test('a man at 89 days is one day short', () {
            expect(
                Eligibility.forLastDonation(DateTime(2026, 6, 29), today, sex: DonorSex.male),
                Eligibility(isEligible: false, daysRemaining: 1, eligibleOn: DateTime(2026, 9, 27)),
            );
        });

        test('a woman exactly 120 days after donating is eligible', () {
            expect(Eligibility.forLastDonation(DateTime(2026, 5, 29), today, sex: DonorSex.female).isEligible, isTrue);
        });

        test('a woman at 119 days is one day short', () {
            expect(Eligibility.forLastDonation(DateTime(2026, 5, 30), today, sex: DonorSex.female).daysRemaining, 1);
        });

        test('not given waits as long as a woman: a man\'s 90 days is not enough', () {
            expect(Eligibility.forLastDonation(DateTime(2026, 6, 28), today).isEligible, isFalse);
            expect(Eligibility.forLastDonation(DateTime(2026, 5, 29), today).isEligible, isTrue);
        });

        test('today is 90 days away for a man, 120 for a woman', () {
            final man = Eligibility.forLastDonation(today, today, sex: DonorSex.male);
            expect(man.daysRemaining, 90);
            expect(man.eligibleOn, DateTime(2026, 12, 25));
            final woman = Eligibility.forLastDonation(today, today, sex: DonorSex.female);
            expect(woman.daysRemaining, 120);
            expect(woman.eligibleOn, DateTime(2027, 1, 24));
        });

        test('the time of day does not move the boundary', () {
            final lateNight = Eligibility.forLastDonation(
                DateTime(2026, 6, 28, 23, 59),
                DateTime(2026, 9, 26, 0, 1),
                sex: DonorSex.male,
            );
            expect(lateNight.isEligible, isTrue);
        });

        test('a daylight-saving-free count: across a month end and a year end', () {
            expect(Eligibility.forLastDonation(DateTime(2026, 12, 20), DateTime(2027, 3, 20), sex: DonorSex.male).isEligible, isTrue);
            expect(Eligibility.forLastDonation(DateTime(2026, 12, 20), DateTime(2027, 3, 19), sex: DonorSex.male).daysRemaining, 1);
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
