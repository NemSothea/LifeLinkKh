import '../../../core/error/result.dart';
import 'blood_request.dart';
import 'blood_request_draft.dart';
import 'hospital.dart';

/// `GET /hospitals`, `POST /requests`, `GET /requests/me`, `GET /requests/{id}` and
/// `POST /requests/{id}/cancel`, as the rest of the app sees them.
abstract interface class RequestRepository {
    /// The request form's dropdown. Fetched, not bundled — `hospitalId` is a
    /// foreign key, and a stale local list turns into a 422 the requester cannot act on.
    Future<Result<List<Hospital>>> fetchHospitals();

    /// Creates the request. Matching and the push alert run inside this one call
    /// (`prd.md` FR-04), so a `Success` here means donors are already being notified.
    Future<Result<BloodRequest>> create(RequestDraft draft);

    /// Every open request in the country, newest first — the same public board the web
    /// portal serves unauthenticated (DEC-009).
    ///
    /// Deliberately *not* `/matches/me`. That call answers "what was I alerted about",
    /// which is empty for a donor between emergencies; this one answers "who needs blood
    /// right now", which is almost never empty. A donor who opens the app unprompted is
    /// asking the second question.
    Future<Result<List<BloodRequest>>> fetchPublicBoard();

    /// The caller's own requests, most recent first.
    Future<Result<List<BloodRequest>>> fetchMine();

    /// A single request. Visible to its creator and to a donor matched to it —
    /// anyone else gets a 404 mapped to [Failure], never a 403, so this call cannot
    /// be used to probe whether an id exists.
    Future<Result<BloodRequest>> fetchDetail(String requestId);

    /// The creator closes the request. 409 if it is already closed.
    Future<Result<BloodRequest>> cancel(String requestId);
}
