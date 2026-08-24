import 'package:flutter/material.dart';

import '../../domain/entities/authentication_mode.dart';
import 'login_page.dart';

/// Dedicated Local Login Screen.
///
/// Responsible strictly for authenticating against local credentials.
/// Contains no server URL input, server validation, sync credentials,
/// or remote server settings.
class LocalLoginPage extends StatelessWidget {
  const LocalLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginPage(mode: AuthenticationMode.local);
  }
}
