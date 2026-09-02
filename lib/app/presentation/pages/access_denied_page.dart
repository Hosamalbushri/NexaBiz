import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../router/app_routes.dart';

/// Page displayed when a user attempts to access a route or module
/// for which they lack authorization or required active company context.
class AccessDeniedPage extends StatelessWidget {
  const AccessDeniedPage({
    super.key,
    this.message,
  });

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Denied'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.gpp_bad_rounded,
                size: 72,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 24),
              const Text(
                'Access Restricted',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message ??
                    'You do not have the required permissions or company authorization to access this page.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRoutes.dashboard);
                  }
                },
                icon: const Icon(Icons.dashboard_rounded),
                label: const Text('Return to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
