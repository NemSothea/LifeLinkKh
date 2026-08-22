import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/src/core/error/failure.dart';
import 'package:lifelink_kh/src/core/error/result.dart';
import 'package:lifelink_kh/src/features/donor/domain/blood_type.dart';
import 'package:lifelink_kh/src/features/request/application/request_service.dart';
import 'package:lifelink_kh/src/features/request/domain/blood_request.dart';
import 'package:lifelink_kh/src/features/request/domain/blood_request_draft.dart';
import 'package:lifelink_kh/src/features/request/domain/hospital.dart';
import 'package:lifelink_kh/src/features/request/domain/request_repository.dart';
import 'package:lifelink_kh/src/features/request/domain/request_status.dart';
import 'package:lifelink_kh/src/features/request/domain/urgency.dart';

void main() {
    late _FakeRequestRepository repository;

    RequestService serviceUnder() => RequestService(repository);

    setUp(() => repository = _FakeRequestRepository());

    const complete = RequestDraft(
        patientBloodType: BloodType.aPositive,
        unitsNeeded: 1,
        hospitalId: 'hospital-1',
        urgency: Urgency.urgent,
        contactName: 'Sophea',
        contactPhone: '012345678',
    );

    group('create', () {
        test('a complete draft reaches the repository', () async {
            final result = await serviceUnder().create(complete);

            expect(result, isA<Success<BloodRequest>>());
            expect(repository.created, isNotNull);
        });

        test('no blood type is refused without a round trip', () async {
            const draft = RequestDraft(
                unitsNeeded: 1,
                hospitalId: 'hospital-1',
                contactName: 'Sophea',
                contactPhone: '012345678',
            );

            final failure = (await serviceUnder().create(draft) as Failed<BloodRequest>).failure;

            expect(
                failure,
                isA<ValidationFailure>().having((f) => f.code, 'code', 'INCOMPLETE_DRAFT'),
            );
            expect(repository.created, isNull, reason: 'no request was sent');
        });

        test('no hospital is refused', () async {
            const draft = RequestDraft(
                patientBloodType: BloodType.aPositive,
                contactName: 'Sophea',
                contactPhone: '012345678',
            );

            expect(await serviceUnder().create(draft), isA<Failed<BloodRequest>>());
            expect(repository.created, isNull);
        });

        test('a blank contact name is refused — the accept flow has nobody to call otherwise', () async {
            const draft = RequestDraft(
                patientBloodType: BloodType.aPositive,
                hospitalId: 'hospital-1',
                contactName: '   ',
                contactPhone: '012345678',
            );

            expect(await serviceUnder().create(draft), isA<Failed<BloodRequest>>());
        });

        test('a blank contact phone is refused', () async {
            const draft = RequestDraft(
                patientBloodType: BloodType.aPositive,
                hospitalId: 'hospital-1',
                contactName: 'Sophea',
            );

            expect(await serviceUnder().create(draft), isA<Failed<BloodRequest>>());
        });
    });

    test('loadHospitals passes the server order through untouched', () async {
        final hospitals = (await serviceUnder().loadHospitals()).valueOrNull!;

        expect(hospitals.map((h) => h.id), ['hospital-1']);
    });

    test('cancel reaches the repository', () async {
        final result = await serviceUnder().cancel('request-1');

        expect(result, isA<Success<BloodRequest>>());
        expect(repository.cancelled, 'request-1');
    });
}

BloodRequest _request() => BloodRequest(
    id: 'request-1',
    status: RequestStatus.open,
    patientBloodType: BloodType.aPositive,
    unitsNeeded: 1,
    urgency: Urgency.urgent,
    hospitalName: 'Calmette Hospital',
    alertedCount: 12,
    acceptedCount: 0,
    createdAt: DateTime(2026, 8, 7, 9, 14),
);

final class _FakeRequestRepository implements RequestRepository {
    RequestDraft? created;
    String? cancelled;

    @override
    Future<Result<List<Hospital>>> fetchHospitals() async =>
        const Success([Hospital(id: 'hospital-1', name: 'Calmette Hospital')]);

    @override
    Future<Result<BloodRequest>> create(RequestDraft draft) async {
        created = draft;
        return Success(_request());
    }

    @override
    Future<Result<List<BloodRequest>>> fetchMine() async => Success([_request()]);

    @override
    Future<Result<BloodRequest>> fetchDetail(String requestId) async => Success(_request());

    @override
    Future<Result<BloodRequest>> cancel(String requestId) async {
        cancelled = requestId;
        return Success(_request());
    }
}
