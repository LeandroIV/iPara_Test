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
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20), // Reduced top spacing
                // Logo and heading
                Center(
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/logo.png',
                        width: 80,
                        height: 80,
                      ), // Smaller logo
                      const SizedBox(height: 16), // Reduced spacing
                      const Text(
                        'How will you use iPara?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8), // Reduced spacing
                      const Text(
                        'Select your role to get started',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24), // Reduced spacing
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
                        const SizedBox(height: 10), // Reduced spacing
                        _buildRoleCard(
                          context,
                          role: UserRole.driver,
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 10), // Reduced spacing
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
                    padding: EdgeInsets.symmetric(
                      vertical: 8.0,
                    ), // Reduced padding
                    child: Text(
                      'You can change your role later in settings',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ), // Smaller font
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _selectRole(context, role),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withAlpha(204),
                color.withAlpha(153),
              ], // Using withAlpha instead of withOpacity
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                radius: 24, // Smaller avatar
                child: Icon(role.icon, color: color, size: 28), // Smaller icon
              ),
              const SizedBox(width: 16), // Reduced spacing
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18, // Smaller font
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4), // Reduced spacing
                    Text(
                      role.description,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ), // Smaller font
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white70,
                size: 16,
              ), // Smaller icon
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
