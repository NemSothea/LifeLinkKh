import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';

/// "14 minutes ago", not "2 Sep 2026 06:13".
///
/// `NOTIFY-donor-alert` screen 2 specifies a request's age as a first-class fact —
/// *"ស្នើសុំនៅ / Requested · ១៤ នាទីមុន / 14 minutes ago"* — and the build shipped an
/// absolute timestamp instead. The difference is not cosmetic. A donor deciding whether
/// to leave the house, and hospital staff deciding which request to chase, both act on
/// elapsed time; nobody subtracts a wall-clock time from now under pressure.
///
/// Past a week it flips back to the absolute date: "nine days ago" is harder to place
/// than "28 Aug 2026", and nothing in this app is urgent at that age.
String formatRelativeTime(
    BuildContext context,
    DateTime timestamp, {
    DateTime? now,
}) {
    final l10n = AppLocalizations.of(context)!;
    // `difference` compares instants, so a UTC `createdAt` off the wire and a local
    // `now` still subtract correctly — no manual `toLocal()` needed.
    final elapsed = (now ?? DateTime.now()).difference(timestamp);

    // A clock skewed a few seconds ahead of the server would otherwise render a
    // negative age; "just now" is the honest reading of a future timestamp here.
    if (elapsed.isNegative || elapsed.inMinutes < 1) return l10n.timeJustNow;
    if (elapsed.inMinutes < 60) return l10n.timeMinutesAgo(elapsed.inMinutes);
    if (elapsed.inHours < 24) return l10n.timeHoursAgo(elapsed.inHours);
    if (elapsed.inDays < 7) return l10n.timeDaysAgo(elapsed.inDays);
    return DateFormat.yMMMd(Localizations.localeOf(context).languageCode).format(timestamp);
}
