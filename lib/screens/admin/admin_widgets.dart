import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/config.dart';
import '../../core/theme.dart';
import '../../data/product_images.dart';
import '../../data/store_data.dart' show storeImageForName;
import '../../widgets/common.dart';

// ------------------------------------------------------------------ helpers
String adminImgUrl(dynamic u) {
  final s = '$u';
  return s.startsWith('http') ? s : '${AppConfig.baseUrl}/$s';
}

bool hasValue(dynamic v) =>
    v != null && '$v'.trim().isNotEmpty && '$v' != 'null';

String fmtDate(dynamic v) {
  final d = DateTime.tryParse('$v');
  return d == null ? '-' : DateFormat('MMM d, y • h:mm a').format(d);
}

String fmtShortDate(dynamic v) {
  final d = DateTime.tryParse('$v');
  return d == null ? '-' : DateFormat('MMM d, y').format(d);
}

void toast(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));

Future<bool> confirmDialog(BuildContext context,
    {required String title,
    required String message,
    String confirmLabel = 'Confirm',
    bool danger = false}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel,
              style: TextStyle(
                  color: danger ? AppColors.error : AppColors.primary)),
        ),
      ],
    ),
  );
  return ok == true;
}

/// Asks for a REQUIRED reason. Returns null if cancelled. Never returns an empty string.
Future<String?> reasonDialog(BuildContext context,
    {required String title,
    required String hint,
    String confirmLabel = 'Submit'}) {
  final ctrl = TextEditingController();
  final formKey = GlobalKey<FormState>();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: ctrl,
          maxLines: 3,
          maxLength: 255,
          autofocus: true,
          decoration: InputDecoration(hintText: hint),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'A reason is required' : null,
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            if (formKey.currentState!.validate())
              Navigator.pop(ctx, ctrl.text.trim());
          },
          child: Text(confirmLabel,
              style: const TextStyle(color: AppColors.error)),
        ),
      ],
    ),
  );
}

// ------------------------------------------------------------------ async view
/// Loads data, shows loading / error states, and rebuilds when [loadKey] changes.
/// [builder] receives a `reload` function (silent refresh, keeps the current data on screen).
class AsyncView<T> extends StatefulWidget {
  final Future<T> Function() load;
  final Object? loadKey;
  final Widget Function(
      BuildContext context, T data, Future<void> Function() reload) builder;
  const AsyncView(
      {super.key, required this.load, required this.builder, this.loadKey});

  @override
  State<AsyncView<T>> createState() => _AsyncViewState<T>();
}

class _AsyncViewState<T> extends State<AsyncView<T>> {
  T? _data;
  bool _hasData = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _run(showSpinner: true);
  }

  @override
  void didUpdateWidget(AsyncView<T> old) {
    super.didUpdateWidget(old);
    if (old.loadKey != widget.loadKey) _run(showSpinner: !_hasData);
  }

  Future<void> _run({bool showSpinner = false}) async {
    if (showSpinner && mounted) setState(() => _loading = true);
    try {
      final d = await widget.load();
      if (!mounted) return;
      setState(() {
        _data = d;
        _hasData = true;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _reload() => _run();

  @override
  Widget build(BuildContext context) {
    if (_loading && !_hasData)
      return const Center(child: CircularProgressIndicator());
    if (_error != null && !_hasData) {
      return ErrorState(
          message: _error!, onRetry: () => _run(showSpinner: true));
    }
    return widget.builder(context, _data as T, _reload);
  }
}

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorState({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off_outlined,
              size: 44, color: AppColors.muted),
          const SizedBox(height: 10),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error)),
          const SizedBox(height: 14),
          SizedBox(
              width: 160,
              child: ElevatedButton(
                  onPressed: onRetry, child: const Text('Try again'))),
        ]),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  const EmptyState(
      {super.key, required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 48, color: AppColors.light),
        const SizedBox(height: 10),
        Text(title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.text)),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        ],
      ]),
    );
  }
}

// ------------------------------------------------------------------ small widgets
class StatusBadge extends StatelessWidget {
  final String status;
  final String? label;
  const StatusBadge(this.status, {super.key, this.label});

  @override
  Widget build(BuildContext context) {
    Color c;
    String text;
    switch (status) {
      case 'approved':
        c = AppColors.primary;
        text = 'Approved';
        break;
      case 'verified':
        c = AppColors.primary;
        text = 'Verified';
        break;
      case 'active':
        c = AppColors.primary;
        text = 'Active';
        break;
      case 'pending':
        c = AppColors.warningText;
        text = 'Pending';
        break;
      case 'rejected':
        c = AppColors.error;
        text = 'Rejected';
        break;
      case 'suspended':
        c = AppColors.error;
        text = 'Suspended';
        break;
      case 'inactive':
        c = AppColors.muted;
        text = 'Inactive';
        break;
      case 'hidden':
        c = AppColors.error;
        text = 'Hidden';
        break;
      default:
        c = AppColors.muted;
        text = status.isEmpty
            ? '-'
            : status[0].toUpperCase() + status.substring(1);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
          color: c.withOpacity(0.14), borderRadius: BorderRadius.circular(20)),
      child: Text(label ?? text,
          style:
              TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class AdminCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  const AdminCard(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(14),
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: cardShadow),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(padding: padding, child: child)),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;
  const StatCard(
      {super.key,
      required this.icon,
      required this.label,
      required this.value,
      required this.color,
      this.onTap});

  /// Taas ng bawat card; gamitin sa grid (mainAxisExtent).
  static const double height = 76;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: cardShadow),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(value,
                          maxLines: 1,
                          style: const TextStyle(
                              fontSize: 19,
                              height: 1.1,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text)),
                      Text(label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.muted)),
                    ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 10),
      child: Row(children: [
        Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark))),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

/// Horizontal filter chips.
class FilterChips extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;
  const FilterChips(
      {super.key,
      required this.options,
      required this.selected,
      required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final o = options[i];
          final on = o == selected;
          return ChoiceChip(
            label: Text(o),
            selected: on,
            onSelected: (_) => onSelected(o),
            selectedColor: AppColors.primary,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
                color: on ? Colors.white : AppColors.text,
                fontWeight: FontWeight.w600,
                fontSize: 13),
            showCheckmark: false,
            side: const BorderSide(color: AppColors.line),
          );
        },
      ),
    );
  }
}

class SearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  const SearchField({super.key, required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}

/// Store photo: uploaded photo -> bundled asset (by name) -> icon.
class StoreImage extends StatelessWidget {
  final String name;
  final dynamic photoUrl;
  final double size;
  const StoreImage(
      {super.key, required this.name, this.photoUrl, this.size = 64});

  @override
  Widget build(BuildContext context) {
    final fallback = SizedBox(
        width: size,
        height: size,
        child: const Center(
            child: Icon(Icons.storefront_outlined, color: AppColors.primary)));
    Widget asset() {
      final path = storeImageForName(name);
      if (path == null) return fallback;
      return Image.asset(path,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: size,
        height: size,
        color: AppColors.background,
        child: hasValue(photoUrl)
            ? Image.network(adminImgUrl(photoUrl),
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => asset())
            : asset(),
      ),
    );
  }
}

/// Product photo: uploaded image_url -> bundled asset (by name) -> placeholder.
class ProductImage extends StatelessWidget {
  final String name;
  final dynamic imageUrl;
  final double size;
  final bool dimmed;
  const ProductImage(
      {super.key,
      required this.name,
      this.imageUrl,
      this.size = 56,
      this.dimmed = false});

  @override
  Widget build(BuildContext context) {
    if (!hasValue(imageUrl))
      return ProductThumb(name: name, size: size, dimmed: dimmed);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Opacity(
          opacity: dimmed ? 0.45 : 1,
          child: Image.network(adminImgUrl(imageUrl),
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  ProductThumb(name: name, size: size, dimmed: dimmed)),
        ),
      ),
    );
  }
}

/// Tap-to-zoom image viewer.
void showImageViewer(BuildContext context, String title, dynamic url) {
  showDialog(
    context: context,
    builder: (_) => Dialog(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
            padding: const EdgeInsets.all(12),
            child: Text(title,
                style: const TextStyle(fontWeight: FontWeight.w700))),
        Flexible(
          child: InteractiveViewer(
            child: Image.network(adminImgUrl(url),
                errorBuilder: (_, __, ___) => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Cannot load image.'))),
          ),
        ),
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close')),
      ]),
    ),
  );
}

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const InfoRow(
      {super.key,
      required this.icon,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            Text(value.isEmpty ? '-' : value,
                style: const TextStyle(fontSize: 14, color: AppColors.text)),
          ]),
        ),
      ]),
    );
  }
}
