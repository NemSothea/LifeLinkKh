/// Geohash encoding, for the `geohash` field on `donors/{uid}` (ADR 0009).
///
/// The matching Function narrows candidates with geohash range queries before computing
/// the exact distance, which is the standard way to do a radius search on Firestore.
/// Hand-written rather than a package: it is twenty lines, and the Function
/// (`geofire-common`) must produce the same strings — the test pins known values.
String encodeGeohash(double latitude, double longitude, {int precision = 10}) {
    const alphabet = '0123456789bcdefghjkmnpqrstuvwxyz';
    var latMin = -90.0, latMax = 90.0;
    var lngMin = -180.0, lngMax = 180.0;
    final out = StringBuffer();
    var bit = 0, char = 0;
    var evenBit = true;
    while (out.length < precision) {
        if (evenBit) {
            final mid = (lngMin + lngMax) / 2;
            if (longitude >= mid) {
                char = (char << 1) | 1;
                lngMin = mid;
            } else {
                char <<= 1;
                lngMax = mid;
            }
        } else {
            final mid = (latMin + latMax) / 2;
            if (latitude >= mid) {
                char = (char << 1) | 1;
                latMin = mid;
            } else {
                char <<= 1;
                latMax = mid;
            }
        }
        evenBit = !evenBit;
        if (++bit == 5) {
            out.write(alphabet[char]);
            bit = 0;
            char = 0;
        }
    }
    return out.toString();
}
