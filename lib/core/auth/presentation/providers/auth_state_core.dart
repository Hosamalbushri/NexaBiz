/// Core authentication state interface and provider export.
///
/// Isolates the application shell and core infrastructure from direct
/// imports of concrete authentication module presentation details.
export '../../../../modules/authentication/presentation/providers/auth_providers.dart'
    show authStateProvider, AuthState, AuthStatus, currentPermissionsProvider;
