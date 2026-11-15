import 'package:flutter/material.dart';
import '../widgets/common.dart';
import 'profile_settings.dart';

class OwnerProfileTab extends StatelessWidget {
  final String? storeStatus;
  final VoidCallback onLogout;
  const OwnerProfileTab({super.key, required this.storeStatus, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final pill = switch (storeStatus) {
      'approved' => 'Approved store',
      'rejected' => 'Store rejected',
      _ => 'Awaiting approval',
    };
    return Column(children: [
      const GradientHead(title: 'Profile', subtitle: 'Store Owner'),
      Expanded(child: ProfileSettings(badge: pill, onLogout: onLogout)),
    ]);
  }
}
