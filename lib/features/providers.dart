import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/invoice.dart';
import '../models/product.dart';
import '../repositories/invoice_repository.dart';
import '../repositories/product_repository.dart';

final repoProvider = Provider((ref) => ProductRepository());
final invoiceRepoProvider = Provider((ref) => InvoiceRepository());
final tabProvider = StateProvider<int>((ref) => 0);
final searchProvider = StateProvider<String>((ref) => '');
final lowOnlyProvider = StateProvider<bool>((ref) => false);

final productsProvider = FutureProvider.autoDispose<List<Product>>((ref) {
  final q = ref.watch(searchProvider);
  final low = ref.watch(lowOnlyProvider);
  return ref.read(repoProvider).search(q, lowOnly: low);
});

final statsProvider = FutureProvider.autoDispose<Stats>((ref) {
  return ref.read(repoProvider).stats();
});

final todayProvider = FutureProvider.autoDispose<TodaySummary>((ref) {
  return ref.read(invoiceRepoProvider).todaySummary();
});

/// يحدّث كل القوائم المعتمدة على المخزون والمبيعات.
void refreshData(WidgetRef ref) {
  ref.invalidate(productsProvider);
  ref.invalidate(statsProvider);
  ref.invalidate(todayProvider);
}
