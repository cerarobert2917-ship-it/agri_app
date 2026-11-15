import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'customer_home.dart';
import 'owner_home.dart';
import 'admin_home.dart';

/// Pinipili ang unang screen ayon sa role ng user.
class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().user;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    switch (user.role) {
      case 'admin':
        return const AdminHome();
      case 'store_owner':
        return OwnerHome(storeStatus: user.storeStatus);
      default:
        return const CustomerHome();
    }
  }
}
