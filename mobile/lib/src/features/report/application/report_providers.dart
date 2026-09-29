import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firestore_providers.dart';
import '../data/firestore_report_repository.dart';
import '../domain/report_repository.dart';

/// Hand-written rather than generated: a full `build_runner` rebuild in this repo crashes and
/// deletes existing `.g.dart` files, and this provider needs nothing codegen adds.
final reportRepositoryProvider = Provider<ReportRepository>(
    (ref) => FirestoreReportRepository(
        ref.watch(firestoreProvider),
        ref.watch(currentUidProvider),
    ),
);
