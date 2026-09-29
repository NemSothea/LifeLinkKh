import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
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
        _controller = AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 1100),
        );
    }

    /// Started here rather than in `initState` because whether it should run at all
    /// depends on `MediaQuery` — and reading an inherited widget is not allowed that
    /// early.
    @override
    void didChangeDependencies() {
        super.didChangeDependencies();
        _syncAnimation();
    }

    @override
    void didUpdateWidget(UrgencyBadge oldWidget) {
        super.didUpdateWidget(oldWidget);
        if (oldWidget.urgency != widget.urgency) _syncAnimation();
    }

    /// The controller used to `repeat()` unconditionally in `initState`, including on
    /// the two urgency levels whose `build` never reads it: every ROUTINE and URGENT
    /// badge drove a 60 fps ticker whose output was discarded, and a list of fifteen
    /// tiles ran fifteen of them. It also made `pumpAndSettle` hang on any screen
    /// showing a badge of any urgency, which is how this was found.
    void _syncAnimation() {
        final shouldPulse = widget.urgency == Urgency.critical &&
            !MediaQuery.of(context).disableAnimations;
        if (shouldPulse && !_controller.isAnimating) {
            _controller.repeat(reverse: true);
        } else if (!shouldPulse && _controller.isAnimating) {
            _controller.stop();
        }
    }

    @override
    void dispose() {
        _controller.dispose();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        final tokens = AppTokens.of(context);

        final (Color background, Color foreground, String label) = switch (widget.urgency) {
            Urgency.critical => (tokens.urgencyHigh, tokens.onUrgencyHigh, l10n.requestUrgencyCritical),
            // The amber lives in AppTokens: Material 3 has no built-in "warning" role.
            Urgency.urgent => (tokens.urgencyMedium, tokens.onUrgencyMedium, l10n.requestUrgencyUrgent),
            Urgency.routine => (tokens.urgencyLow, tokens.onUrgencyLow, l10n.requestUrgencyRoutine),
        };

        final badge = DecoratedBox(
            decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
            child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.space8 + 2,
                    vertical: AppTokens.space4,
                ),
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
