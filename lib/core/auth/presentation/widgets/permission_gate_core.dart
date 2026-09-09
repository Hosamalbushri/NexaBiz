/// Core authorization UX gate exports.
///
/// Prevents secondary modules from directly importing authentication module UI widgets.
library;

export '../../../../modules/authentication/presentation/widgets/permission_gate.dart'
    show PermissionGate, RoleGate, canAccess;
