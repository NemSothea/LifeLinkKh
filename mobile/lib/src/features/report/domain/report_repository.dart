import '../../../core/error/result.dart';
import 'report_reason.dart';

/// Files a donor's report about a request they were alerted to (DEC-019).
abstract interface class ReportRepository {
    /// One report per donor per request. A second one is refused by the rules and comes
    /// back as a `ForbiddenFailure`.
    Future<Result<void>> report({
        required String requestId,
        required ReportReason reason,
        String? note,
    });
}
