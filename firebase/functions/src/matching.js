// Who a request alerts — the port of DonorCandidateRepository.findCandidates (ADR 0009).
//
// Pure: no Firestore, no clock of its own. index.js reads the donors and passes them in, so
// every clause below is unit-tested without an emulator. Each clause is the SQL one, and the
// comment on each says which line it was.

/** Days between donations. EligibilityCalculator.COOLDOWN_DAYS; the app's Eligibility.cooldownDays. */
export const COOLDOWN_DAYS = 56;

/** ADR 0008: a ceiling, never a target. lifelink.matching.max-notified. */
export const MAX_NOTIFIED = 25;

/** lifelink.matching.radius-km. */
export const RADIUS_KM = 10;

/**
 * ADR 0004: recipient (patient) → the donor types they can receive. The same rows as the
 * blood_compatibility table. The direction is the one thing a table cannot protect: swapping
 * it runs, returns donors, and offers an O− patient every donor in the city.
 */
export const COMPATIBLE_DONORS = Object.freeze({
  'O-': ['O-'],
  'O+': ['O+', 'O-'],
  'A-': ['A-', 'O-'],
  'A+': ['A+', 'A-', 'O+', 'O-'],
  'B-': ['B-', 'O-'],
  'B+': ['B+', 'B-', 'O+', 'O-'],
  'AB-': ['A-', 'AB-', 'B-', 'O-'],
  'AB+': ['A+', 'A-', 'AB+', 'AB-', 'B+', 'B-', 'O+', 'O-'],
});

/** Calendar date in Phnom Penh as 'YYYY-MM-DD' — the server's "today", whatever its own zone. */
export function phnomPenhDate(instant) {
  return new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Asia/Phnom_Penh',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).format(instant);
}

/** 'YYYY-MM-DD' minus `days`, in calendar days. */
function minusDays(isoDate, days) {
  const d = new Date(`${isoDate}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() - days);
  return d.toISOString().slice(0, 10);
}

/**
 * Great-circle distance, the same spherical law of cosines the SQL used, clamped with
 * Math.min(1, …) because floating point can push the argument a hair above 1 for two points
 * at the same place. Null in, null out — never 0: that was the least(NULL) trap.
 */
export function distanceKm(lat1, lng1, lat2, lng2) {
  if ([lat1, lng1, lat2, lng2].some((v) => v == null)) return null;
  const rad = (deg) => (deg * Math.PI) / 180;
  const cos = Math.cos(rad(lat1)) * Math.cos(rad(lat2)) * Math.cos(rad(lng2) - rad(lng1))
    + Math.sin(rad(lat1)) * Math.sin(rad(lat2));
  return 6371 * Math.acos(Math.min(1, cos));
}

/**
 * Compatible, available, eligible donors within the radius, nearest first.
 *
 * @param {object} args
 * @param {{patientBloodType: string, createdBy: string}} args.request
 * @param {{lat: number, lng: number}} args.hospital
 * @param {Array<{uid: string, bloodType: string, isAvailable: boolean,
 *   lastDonationDate: string|null, lat: number|null, lng: number|null}>} args.donors
 *   lastDonationDate already converted to a Phnom Penh 'YYYY-MM-DD'.
 * @param {Date} args.now
 * @returns {Array<{uid: string, distanceKm: number|null}>}
 */
export function selectCandidates({
  request,
  hospital,
  donors,
  now,
  radiusKm = RADIUS_KM,
  maxNotified = MAX_NOTIFIED,
}) {
  const compatible = COMPATIBLE_DONORS[request.patientBloodType];
  if (!compatible) return [];
  const eligibleCutoff = minusDays(phnomPenhDate(now), COOLDOWN_DAYS);

  return donors
    // JOIN blood_compatibility ON bc.donor_type = dp.blood_type AND bc.recipient_type = :patient
    .filter((d) => compatible.includes(d.bloodType))
    // dp.is_available = true
    .filter((d) => d.isAvailable === true)
    // dp.user_id <> :requesterUserId — a donor is never alerted to donate to themselves.
    .filter((d) => d.uid !== request.createdBy)
    // last_donation_date IS NULL OR last_donation_date <= :eligibleCutoff (inclusive boundary)
    .filter((d) => d.lastDonationDate == null || d.lastDonationDate <= eligibleCutoff)
    .map((d) => ({ uid: d.uid, raw: distanceKm(hospital.lat, hospital.lng, d.lat, d.lng) }))
    // c.latitude IS NULL OR c.distance_km <= :radiusKm — no GPS still matches (ADR 0003).
    .filter((c) => c.raw == null || c.raw <= radiusKm)
    // ROUND(distance_km * 2, 0) / 2 — half-kilometre precision, never the exact figure.
    .map((c) => ({ uid: c.uid, distanceKm: c.raw == null ? null : Math.round(c.raw * 2) / 2 }))
    // ORDER BY "distanceKm" ASC NULLS LAST, c.id ASC — the tie-break keeps re-runs stable.
    .sort((a, b) => {
      if (a.distanceKm == null && b.distanceKm != null) return 1;
      if (b.distanceKm == null && a.distanceKm != null) return -1;
      if (a.distanceKm !== b.distanceKm) return a.distanceKm - b.distanceKm;
      return a.uid < b.uid ? -1 : a.uid > b.uid ? 1 : 0;
    })
    // LIMIT :maxNotified
    .slice(0, maxNotified);
}

/** RequestRateLimiter: at most 5 requests per creator in any 10 minutes. */
export const REQUEST_RATE_LIMIT = Object.freeze({ maxAttempts: 5, windowMs: 10 * 60 * 1000 });
