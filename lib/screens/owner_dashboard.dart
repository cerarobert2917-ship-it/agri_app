import 'package:flutter/material.dart';
import '../core/helpers.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

class OwnerDashboard extends StatelessWidget {
  final Map<String, dynamic> store;
  final List<Map<String, dynamic>> products;
  final VoidCallback onAdd;
  final Future<void> Function() onRefresh;
  const OwnerDashboard({super.key, required this.store, required this.products, required this.onAdd, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final low = products.where((p) => stockStatus(p) == 'low').length;
    final out = products.where((p) => stockStatus(p) == 'out').length;
    final recent = [...products]..sort((a, b) {
        final da = lastUpdated(a) ?? DateTime(2000);
        final db = lastUpdated(b) ?? DateTime(2000);
        return db.compareTo(da);
      });

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Text('${store['name']}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
        Text('${store['barangay']}, Mamburao', style: const TextStyle(color: AppColors.muted)),
        const SizedBox(height: 16),
        Row(children: [
          _stat('Produkto', products.length, Icons.inventory_2_outlined, AppColors.primary),
          const SizedBox(width: 10),
          _stat('Paubos Na', low, Icons.warning_amber_rounded, AppColors.warning),
          const SizedBox(width: 10),
          _stat('Ubos', out, Icons.remove_shopping_cart_outlined, AppColors.error),
        ]),
        const SizedBox(height: 16),
        ElevatedButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Magdagdag ng Produkto')),
        const SizedBox(height: 20),
        const Text('Mga huling update', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (recent.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Wala pang produkto. Magdagdag ng una mong produkto.', style: TextStyle(color: AppColors.muted)),
          ),
        for (final p in recent.take(5))
          Card(
            child: ListTile(
              title: Text('${p['name']}'),
              subtitle: Text('${peso(p['price'])} • stock ${asInt(p['stock_quantity'])} • ${whenText(lastUpdated(p))}'),
              trailing: StockBadge(stockStatus(p)),
            ),
          ),
      ]),
    );
  }

  Widget _stat(String label, int value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(children: [
            Icon(icon, color: color),
            const SizedBox(height: 6),
            Text('$value', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ]),
        ),
      ),
    );
  }
}
