import 'package:lifelink_kh/src/core/api/portal_api.dart';

/// A [PortalApi] a test programs: [handler] answers each call — returning the function's
/// result, or throwing a [PortalCallException] the way the real one would. Records every
/// call so a test can assert what was sent.
final class FakePortalApi implements PortalApi {
    FakePortalApi([this.handler]);

    Future<Object?> Function(String name, Object? data)? handler;

    final List<({String name, Object? data})> calls = [];

    @override
    Future<Object?> call(String name, [Object? data]) async {
        calls.add((name: name, data: data));
        final handler = this.handler;
        if (handler == null) throw UnimplementedError('no handler for $name');
        return handler(name, data);
    }
}
