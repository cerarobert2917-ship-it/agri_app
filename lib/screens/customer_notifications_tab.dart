import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../data/product_images.dart';
import '../services/change_notification_service.dart';
import '../widgets/common.dart';

enum _Filter { all, price, stock }

const _orange = Color(0xFFEF6C00);

/// Mga pagbabago ng presyo at stock na ginawa ng mga owner (totoong data mula sa backend).
class CustomerNotificationsTab extends StatefulWidget {
  final ChangeNotificationService service;
  const CustomerNotificationsTab({super.key, required this.service});

  @override
  State<CustomerNotificationsTab> createState() =>
      _CustomerNotificationsTabState();
}

class _CustomerNotificationsTabState extends State<CustomerNotificationsTab> {
  _Filter _filter = _Filter.all;
  final Set<int> _removing = {}; // mga card na nag-a-animate palabas

  @override
  void initState() {
    super.initState();
    widget.service.refresh();
  }

  bool _matches(ChangeItem c) {
    switch (_filter) {
      case _Filter.price:
        return c.priceChanged;
      case _Filter.stock:
        return c.stockChanged;
      case _Filter.all:
        return true;
    }
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear all notifications?'),
        content: const Text(
            'All notifications will be removed from your list. New price and stock updates will still appear here.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear all',
                style: TextStyle(
                    color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await widget.service.clearAll();
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(
              content: Text('All notifications cleared.'),
              duration: Duration(seconds: 2)));
      }
    }
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
          SnackBar(content: Text(text), duration: const Duration(seconds: 2)));
  }

  /// Dismiss gamit ang ✕: i-animate muna (fade + collapse), saka buburahin.
  Future<void> _dismissAnimated(ChangeItem c) async {
    setState(() => _removing.add(c.id));
    await Future.delayed(const Duration(milliseconds: 260));
    if (!mounted) return;
    await widget.service.delete(c);
    if (!mounted) return;
    setState(() => _removing.remove(c.id));
    _toast('Notification deleted.');
  }

  /// Dismiss gamit ang swipe (may sariling animation na ang Dismissible).
  void _dismissSwiped(ChangeItem c) {
    widget.service.delete(c);
    _toast('Notification deleted.');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.service,
      builder: (context, _) {
        final s = widget.service;
        final all = s.items;
        final shown = all.where(_matches).toList();
        int unread(bool Function(ChangeItem) f) =>
            all.where((c) => f(c) && c.id > s.lastSeenId).length;

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
          ),
          child: Column(children: [
            const _Header(),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                  child: _body(s, all, shown, unread),
                ),
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _body(ChangeNotificationService s, List<ChangeItem> all,
      List<ChangeItem> shown, int Function(bool Function(ChangeItem)) unread) {
    // loading state (unang pag-load)
    if (!s.loadedOnce) return const Center(child: CircularProgressIndicator());

    // error state (walang laman at pumalya)
    if (s.error != null && all.isEmpty) {
      return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.12),
            _ErrorView(message: s.error!, onRetry: s.refresh),
          ]);
    }

    final unreadCount = s.unreadCount;
    return RefreshIndicator(
      onRefresh: s.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          if (s.error != null)
            Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ErrorBanner(s.error!)),
          _FilterBar(
            selected: _filter,
            onSelect: (f) => setState(() => _filter = f),
            unreadAll: unreadCount,
            unreadPrice: unread((c) => c.priceChanged),
            unreadStock: unread((c) => c.stockChanged),
          ),
          if (all.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: _PillButton(
                  icon: Icons.done_all,
                  label: unreadCount > 0 ? 'Mark all as read' : 'All read',
                  color: AppColors.primaryDark,
                  background: AppColors.light.withOpacity(0.55),
                  onTap: unreadCount > 0 ? s.markAllRead : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PillButton(
                  icon: Icons.delete_outline,
                  label: 'Clear all',
                  color: AppColors.error,
                  background: AppColors.error.withOpacity(0.10),
                  onTap: _confirmClear,
                ),
              ),
            ]),
          ],
          const SizedBox(height: 12),
          if (shown.isEmpty)
            _EmptyState(filtered: all.isNotEmpty, filter: _filter)
          else
            for (final c in shown)
              _RemovableItem(
                key: ValueKey('chg-${c.id}'),
                removing: _removing.contains(c.id),
                onSwiped: () => _dismissSwiped(c),
                child: _ChangeCard(c,
                    isNew: c.id > s.lastSeenId,
                    onDismiss: () => _dismissAnimated(c)),
              ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ header
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20 + MediaQuery.of(context).padding.top, 20, 24),
      child: Row(children: [
        // AgriMamView logo, walang background box. May manipis na puting outline sa mismong logo para kita sa berde.
        Image.asset('assets/images/agrimamview_logo_outline.png',
            height: 48, fit: BoxFit.contain),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Notifications',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 3),
            Text('Stay updated on store price and stock changes.',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13.5,
                    height: 1.25)),
          ]),
        ),
      ]),
    );
  }
}

// ------------------------------------------------------------------ filters
class _FilterBar extends StatelessWidget {
  final _Filter selected;
  final ValueChanged<_Filter> onSelect;
  final int unreadAll, unreadPrice, unreadStock;
  const _FilterBar({
    required this.selected,
    required this.onSelect,
    required this.unreadAll,
    required this.unreadPrice,
    required this.unreadStock,
  });

  Widget _seg(_Filter f, IconData icon, String label, int badge) {
    final on = selected == f;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onSelect(f),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          height: 34,
          decoration: BoxDecoration(
            color: on ? AppColors.primaryDark : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: on
                ? const [
                    BoxShadow(
                        color: Color(0x331B5E20),
                        blurRadius: 8,
                        offset: Offset(0, 3))
                  ]
                : null,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon,
                    size: 16, color: on ? Colors.white : AppColors.muted),
                const SizedBox(width: 5),
                Text(label,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: on ? Colors.white : AppColors.text)),
                if (badge > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    constraints:
                        const BoxConstraints(minWidth: 20, minHeight: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.all(Radius.circular(10))),
                    child: Text(badge > 99 ? '99+' : '$badge',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800)),
                  ),
                ],
              ]),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
        boxShadow: cardShadow,
      ),
      child: Row(children: [
        _seg(_Filter.all, Icons.notifications_none, 'All', unreadAll),
        _seg(_Filter.price, Icons.sell_outlined, 'Price', unreadPrice),
        _seg(_Filter.stock, Icons.inventory_2_outlined, 'Stock', unreadStock),
      ]),
    );
  }
}

class _PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color background;
  final VoidCallback? onTap;
  const _PillButton(
      {required this.icon,
      required this.label,
      required this.color,
      required this.background,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: SizedBox(
            height: 34,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(icon, size: 16, color: color),
                    const SizedBox(width: 6),
                    Text(label,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: color)),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ list item (swipe + animated removal)
class _RemovableItem extends StatelessWidget {
  final bool removing;
  final VoidCallback onSwiped;
  final Widget child;
  const _RemovableItem(
      {super.key,
      required this.removing,
      required this.onSwiped,
      required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: removing
          ? const SizedBox(width: double.infinity, height: 0)
          : Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Dismissible(
                  key: key!,
                  onDismissed: (_) => onSwiped(),
                  background: const _SwipeBg(Alignment.centerLeft),
                  secondaryBackground: const _SwipeBg(Alignment.centerRight),
                  child: child,
                ),
              ),
            ),
    );
  }
}

class _SwipeBg extends StatelessWidget {
  final Alignment align;
  const _SwipeBg(this.align);

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.error,
        alignment: align,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      );
}

// ------------------------------------------------------------------ notification kinds
class _Kind {
  final String label;
  final IconData icon;
  final Color color;
  const _Kind(this.label, this.icon, this.color);
}

_Kind? _priceKind(ChangeItem c) {
  if (!c.priceChanged) return null;
  return c.newPrice! < c.oldPrice!
      ? const _Kind('Price dropped', Icons.trending_down, AppColors.primary)
      : const _Kind('Price increased', Icons.trending_up, AppColors.error);
}

_Kind? _stockKind(ChangeItem c) {
  if (!c.stockChanged) return null;
  final o = c.oldStock!, n = c.newStock!;
  if (n == 0)
    return const _Kind(
        'Out of stock', Icons.remove_shopping_cart_outlined, AppColors.error);
  if (o == 0)
    return const _Kind(
        'Back in stock', Icons.inventory_2_outlined, AppColors.primary);
  if (n < o && n < 10)
    return const _Kind('Low stock', Icons.warning_amber_rounded, _orange);
  if (n > o)
    return const _Kind('Stock increased', Icons.north, AppColors.primary);
  return const _Kind('Stock decreased', Icons.south, _orange);
}

String _ago(DateTime? d) {
  if (d == null) return '';
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} hr ago';
  if (diff.inDays < 7) return '${diff.inDays} d ago';
  return DateFormat('MMM d').format(d);
}

class _TypeChip extends StatelessWidget {
  final _Kind kind;
  const _TypeChip(this.kind);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
          color: kind.color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(kind.icon, size: 15, color: kind.color),
        const SizedBox(width: 4),
        Text(kind.label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: kind.color)),
      ]),
    );
  }
}

// ------------------------------------------------------------------ card
class _ChangeCard extends StatelessWidget {
  final ChangeItem c;
  final bool isNew;
  final VoidCallback onDismiss;
  const _ChangeCard(this.c, {required this.isNew, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    final price = _priceKind(c);
    final stock = _stockKind(c);
    final accent = (price ?? stock)?.color ?? AppColors.primary;
    final when = c.createdAt == null
        ? ''
        : '${_ago(c.createdAt)} • ${DateFormat('MMM d, h:mm a').format(c.createdAt!)}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isNew
                ? AppColors.primary.withOpacity(0.35)
                : Colors.transparent,
            width: 1.2),
        boxShadow: cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Stack(children: [
          // kulay sa kaliwa: berde = bumaba ang presyo / dumami, pula = tumaas / naubos, orange = mababa ang stock
          Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 5,
              child: ColoredBox(color: accent)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 6, 12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Stack(clipBehavior: Clip.none, children: [
                ProductThumb(name: c.productName, size: 58),
                if (isNew)
                  Positioned(
                    left: -4,
                    top: -4,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2)),
                    ),
                  ),
              ]),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 30),
                        child: Text(c.productName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    isNew ? FontWeight.w800 : FontWeight.w700,
                                height: 1.2)),
                      ),
                      const SizedBox(height: 3),
                      Row(children: [
                        const Icon(Icons.storefront_outlined,
                            size: 15, color: AppColors.muted),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text('${c.storeName} • ${c.packaging}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12.5, color: AppColors.muted)),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      if (price != null)
                        Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(money.format(c.oldPrice),
                                  style: const TextStyle(
                                      fontSize: 13.5,
                                      color: AppColors.muted,
                                      decoration: TextDecoration.lineThrough)),
                              const Icon(Icons.arrow_forward,
                                  size: 15, color: AppColors.muted),
                              Text(money.format(c.newPrice),
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: price.color)),
                              _TypeChip(price),
                            ]),
                      if (price != null && stock != null)
                        const SizedBox(height: 8),
                      if (stock != null)
                        Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                  c.newStock == 0
                                      ? 'No stock left'
                                      : 'Stock: ${c.oldStock} → ${c.newStock}',
                                  style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600)),
                              _TypeChip(stock),
                            ]),
                      if (when.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(children: [
                          const Icon(Icons.schedule,
                              size: 14, color: AppColors.muted),
                          const SizedBox(width: 5),
                          Expanded(
                              child: Text(when,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 11.5, color: AppColors.muted))),
                        ]),
                      ],
                    ]),
              ),
            ]),
          ),
          // dismiss button
          Positioned(
            top: 4,
            right: 4,
            child: SizedBox(
              width: 34,
              height: 34,
              child: IconButton(
                tooltip: 'Dismiss',
                padding: EdgeInsets.zero,
                iconSize: 20,
                icon: const Icon(Icons.close, color: AppColors.muted),
                onPressed: onDismiss,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ------------------------------------------------------------------ empty / error
class _EmptyState extends StatelessWidget {
  final bool filtered; // may notifications, pero walang tumugma sa filter
  final _Filter filter;
  const _EmptyState({required this.filtered, required this.filter});

  @override
  Widget build(BuildContext context) {
    final title = !filtered
        ? 'No notifications yet'
        : filter == _Filter.price
            ? 'No price updates'
            : 'No stock updates';
    final message = !filtered
        ? 'When a store changes the price or stock of a product, the update will appear here.'
        : 'Nothing to show in this filter right now. Try "All" to see everything.';
    return Padding(
      padding: EdgeInsets.fromLTRB(
          28, MediaQuery.of(context).size.height * 0.07, 28, 0),
      child: Column(children: [
        Container(
          width: 104,
          height: 104,
          decoration: BoxDecoration(
              color: AppColors.light.withOpacity(0.55), shape: BoxShape.circle),
          child: const Icon(Icons.notifications_none_rounded,
              size: 54, color: AppColors.primary),
        ),
        const SizedBox(height: 18),
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(message,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.muted, fontSize: 14, height: 1.35)),
      ]),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(children: [
        const Icon(Icons.cloud_off_outlined, size: 52, color: AppColors.muted),
        const SizedBox(height: 12),
        const Text('Could not load notifications',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.error, fontSize: 13)),
        const SizedBox(height: 16),
        SizedBox(
            width: 160,
            child: ElevatedButton(
                onPressed: onRetry, child: const Text('Try again'))),
      ]),
    );
  }
}
