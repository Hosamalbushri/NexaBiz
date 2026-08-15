import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'authenticated_http_client.dart';

/// App auth wiring overrides this with a real JWT client.
///
/// Kept in Core so SyncManager / HttpRemoteSyncApi never import modules.
final syncAuthenticatedHttpClientProvider =
    Provider<AuthenticatedHttpClient?>((ref) => null);
