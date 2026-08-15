/// Authentication / session / RBAC snapshot for the offline-first app.
///
/// Business modules must not call HTTP auth directly — use providers here.
library;

export 'data/auth_repository_impl.dart';
export 'data/secure_token_storage.dart';
export 'domain/entities/auth_session.dart';
export 'domain/entities/auth_user.dart';
export 'domain/repositories/auth_repository.dart';
export 'presentation/providers/auth_providers.dart';
export 'presentation/widgets/permission_gate.dart';
