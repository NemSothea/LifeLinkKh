// `show`, because cloud_functions exports a `Result` of its own (streaming callables)
// that would shadow the app's.
import 'package:cloud_functions/cloud_functions.dart'
    show FirebaseFunctions, FirebaseFunctionsException;

import 'portal_api.dart';

/// The real [PortalApi]: `cloud_functions`' `httpsCallableFromUrl` against the portal
/// (ADR 0010). The plugin does what it did for the Cloud Functions — attaches the
/// signed-in user's ID token as the bearer, sends `{data}`, decodes `{result}`, and turns
/// `{error}` into a [FirebaseFunctionsException] with the same codes — so nothing about
/// authentication or error handling moved with the address.
final class FunctionsPortalApi implements PortalApi {
    FunctionsPortalApi(this._functions, {required String baseUrl})
        : _baseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

    final FirebaseFunctions _functions;
    final String _baseUrl;

    @override
    Future<Object?> call(String name, [Object? data]) async {
        final callable = _functions.httpsCallableFromUrl('$_baseUrl/api/functions/$name');
        try {
            return (await callable.call<Object?>(data)).data;
        } on FirebaseFunctionsException catch (error) {
            throw PortalCallException(
                code: error.code,
                details: error.details,
                message: error.message,
            );
        }
    }
}
