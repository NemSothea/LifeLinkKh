import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/src/features/request/domain/request_status.dart';

/// DEC-015 added two wire values. A status the client cannot parse makes the whole
/// request unreadable (`_requestFrom` throws rather than guess), so a requester whose
/// request is waiting for review would see an error instead of it.
void main() {
    test('every wire value parses, including the two review states', () {
        expect(RequestStatus.fromWire('PENDING'), RequestStatus.pending);
        expect(RequestStatus.fromWire('OPEN'), RequestStatus.open);
        expect(RequestStatus.fromWire('REJECTED'), RequestStatus.rejected);
        expect(RequestStatus.fromWire('FULFILLED'), RequestStatus.fulfilled);
        expect(RequestStatus.fromWire('CANCELLED'), RequestStatus.cancelled);
        expect(RequestStatus.fromWire('EXPIRED'), RequestStatus.expired);
    });

    test('an unknown or missing value is null, never a default', () {
        expect(RequestStatus.fromWire('pending'), isNull);
        expect(RequestStatus.fromWire(null), isNull);
    });

    test('only PENDING and OPEN can be cancelled — what the rules allow', () {
        expect(
            RequestStatus.values.where((s) => s.isCancellable),
            [RequestStatus.pending, RequestStatus.open],
        );
    });
}
