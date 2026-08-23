import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../domain/urgency.dart';

/// Colour-coded urgency, matching the portal's own badge (`URGENCY_STYLE` in
/// `frontend/.../portal/page.tsx`) — a donor scanning a list should be able to spot a
/// `CRITICAL` request by shape and colour, not by reading the word every time.
///
/// `CRITICAL` pulses gently — the one urgency level where "someone might miss this in
/// a quick glance" has a real cost. `MediaQuery.disableAnimations` (the platform's
/// reduce-motion setting) turns it off; the colour and label alone still carry the
/// meaning.
class UrgencyBadge extends StatefulWidget {
    const UrgencyBadge({required this.urgency, super.key});

    final Urgency urgency;

    @override
    State<UrgencyBadge> createState() => _UrgencyBadgeState();
}

class _UrgencyBadgeState extends State<UrgencyBadge> with SingleTickerProviderStateMixin {
    late final AnimationController _controller;

    @override
    void initState() {
        super.initState();
        _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
            ..repeat(reverse: true);
    }

    @override
    void dispose() {
        _controller.dispose();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        final scheme = Theme.of(context).colorScheme;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        final (Color background, Color foreground, String label) = switch (widget.urgency) {
            Urgency.critical => (
                scheme.errorContainer,
                scheme.onErrorContainer,
                l10n.requestUrgencyCritical,
            ),
            // Material 3 has no built-in "warning" role — hand-picked amber, tuned per
            // brightness rather than a single hard-coded pair that would wash out or
            // glow depending on the theme.
            Urgency.urgent => isDark
                ? (const Color(0xFF4A3600), const Color(0xFFFFD989), l10n.requestUrgencyUrgent)
                : (const Color(0xFFFFF1C4), const Color(0xFF7A5900), l10n.requestUrgencyUrgent),
            Urgency.routine => (
                scheme.surfaceContainerHighest,
                scheme.onSurfaceVariant,
                l10n.requestUrgencyRoutine,
            ),
        };

        final badge = DecoratedBox(
            decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Text(
                    label,
                    style: TextStyle(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 0.4,
                    ),
                ),
            ),
        );

        if (widget.urgency != Urgency.critical || MediaQuery.of(context).disableAnimations) {
            return badge;
        }

        return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Opacity(opacity: 0.65 + (_controller.value * 0.35), child: child),
            child: badge,
        );
    }
}
