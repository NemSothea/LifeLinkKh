import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'link_opener.dart';

part 'link_providers.g.dart';

/// Tests override this with a recording fake. Nothing reaches the platform until a link
/// is actually tapped, so the real default costs a widget test nothing.
@Riverpod(keepAlive: true)
LinkOpener linkOpener(LinkOpenerRef ref) => const UrlLauncherLinkOpener();
