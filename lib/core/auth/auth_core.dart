/// Core authentication domain exports and ports.
///
/// Re-exports session context, authentication state, permission gates, and auth entities.
library;

export '../../modules/authentication/data/local_auth_store.dart';
export '../../modules/authentication/domain/entities/auth_session.dart';
export '../../modules/authentication/domain/entities/auth_user.dart';
export 'ports/session_context_port.dart';
export 'presentation/providers/auth_state_core.dart';
export 'presentation/widgets/permission_gate_core.dart';
