import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/units.dart';
import '../providers.dart';
import 'product_form.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final lowOnly = ref.watch(lowOnlyProvider);
    return Scaffold(
      appBar: AppBar(title: Text(lowOnly ? 'النقوصات' : 'المنتجات')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProductForm()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('منتج جديد'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'ابحث بالاسم أو الباركود',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => ref.read(searchProvider.notifier).state = v,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('النقوصات فقط'),
                  selected: lowOnly,
                  onSelected: (v) =>
                      ref.read(lowOnlyProvider.notifier).state = v,
                ),
              ],
            ),
          ),
          Expanded(
            child: products.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => const Center(child: Text('تعذر تحميل المنتجات')),
              data: (list) {
                if (list.isEmpty) {
                  return const Center(child: Text('لا توجد منتجات'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final p = list[i];
                    final low = p.isLow;
                    return Card(
                      color: low ? AppColors.danger.withOpacity(0.08) : null,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => ProductForm(product: p)),
                        ),
                        title: Text(p.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                          '${Units.format(p.qtyPieces, p.piecesPerCarton)}'
                          '  •  ${p.barcode ?? 'بدون باركود'}',
                          style: TextStyle(
                              color: low ? AppColors.danger : null),
                        ),
                        trailing: Text(iqd(p.salePrice),
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.emerald)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
