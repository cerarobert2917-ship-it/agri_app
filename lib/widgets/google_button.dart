import 'package:flutter/material.dart';
import '../core/theme.dart';

/// "or" divider + "Continue with Google" button.
class GoogleButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool loading;
  final bool showDivider;
  final double height;
  final double radius;
  const GoogleButton(
      {super.key,
      required this.onPressed,
      this.loading = false,
      this.showDivider = true,
      this.height = 50,
      this.radius = 14});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (showDivider)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Row(children: [
            Expanded(child: Divider(color: AppColors.line)),
            Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('or', style: TextStyle(color: AppColors.muted))),
            Expanded(child: Divider(color: AppColors.line)),
          ]),
        ),
      OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: Size.fromHeight(height),
          backgroundColor: Colors.white,
          side: const BorderSide(color: AppColors.line),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius)),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('G',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF4285F4))),
                const SizedBox(width: 10),
                const Text('Continue with Google',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text)),
              ]),
      ),
    ]);
  }
}

/// Tinatanong kung Customer o Store Owner ang bagong Google account.
/// Ibabalik ang 'customer' / 'store_owner', o null kung na-cancel.
Future<String?> askGoogleRole(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Welcome! Who are you?'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Choose how you will use the app.',
            style: TextStyle(color: AppColors.muted)),
        const SizedBox(height: 16),
        _roleTile(ctx, 'customer', 'Viewer', 'Find products and stores',
            Icons.visibility_outlined),
        const SizedBox(height: 10),
        _roleTile(ctx, 'store_owner', 'Store Owner',
            'Manage your store and products', Icons.storefront_outlined),
      ]),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))
      ],
    ),
  );
}

Widget _roleTile(
    BuildContext ctx, String value, String title, String sub, IconData icon) {
  return InkWell(
    borderRadius: BorderRadius.circular(14),
    onTap: () => Navigator.pop(ctx, value),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Icon(icon, color: AppColors.primary, size: 30),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(sub,
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ]),
        ),
      ]),
    ),
  );
}
