/// Authentication / session / RBAC snapshot for the offline-first app.
library;

export 'data/local_auth_repository.dart';
export 'data/local_auth_store.dart';
export 'data/secure_token_storage.dart';
export 'domain/entities/auth_session.dart';
export 'domain/entities/auth_user.dart';
export 'domain/local_permissions.dart';
export 'domain/repositories/auth_repository.dart';
export 'presentation/providers/auth_providers.dart';
export 'presentation/widgets/permission_gate.dart';
