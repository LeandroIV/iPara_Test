import 'package:flutter/material.dart';
import '../models/user_role.dart';
import '../services/user_service.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Color(0xFF1A1A1A)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // Logo and heading
                Center(
                  child: Column(
                    children: [
                      Image.asset('assets/logo.png', width: 100, height: 100),
                      const SizedBox(height: 24),
                      const Text(
                        'How will you use iPara?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Select your role to get started',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Role selection cards
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildRoleCard(
                          context,
                          role: UserRole.commuter,
                          color: Colors.amber,
                        ),
                        const SizedBox(height: 16),
                        _buildRoleCard(
                          context,
                          role: UserRole.driver,
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 16),
                        _buildRoleCard(
                          context,
                          role: UserRole.operator,
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ),
                ),

                // Can change later note
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      'You can change your role later in settings',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required UserRole role,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _selectRole(context, role),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.8), color.withOpacity(0.6)],
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                radius: 28,
                child: Icon(role.icon, color: color, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      role.description,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectRole(BuildContext context, UserRole role) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Save the selected role
      await UserService.saveUserRole(role);

      // Close loading dialog and navigate based on role
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        // Navigate to the appropriate screen based on role
        Navigator.of(context).pushNamedAndRemoveUntil(
          _getInitialRouteForRole(role),
          (route) => false,
        );
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _getInitialRouteForRole(UserRole role) {
    switch (role) {
      case UserRole.commuter:
        return '/commuter/home';
      case UserRole.driver:
        return '/driver/home';
      case UserRole.operator:
        return '/operator/home';
    }
  }
}
