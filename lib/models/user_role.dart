import 'package:flutter/material.dart';

enum UserRole { commuter, driver, operator }

extension UserRoleExtension on UserRole {
  String get name {
    switch (this) {
      case UserRole.commuter:
        return 'Commuter';
      case UserRole.driver:
        return 'Driver';
      case UserRole.operator:
        return 'Operator';
    }
  }

  String get description {
    switch (this) {
      case UserRole.commuter:
        return 'Find and book rides on public transport';
      case UserRole.driver:
        return 'Accept ride requests and manage your routes';
      case UserRole.operator:
        return 'Manage your fleet and monitor operations';
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.commuter:
        return Icons.person;
      case UserRole.driver:
        return Icons.drive_eta;
      case UserRole.operator:
        return Icons.business;
    }
  }
}
