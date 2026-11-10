import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../repositories/product_repository.dart';

final repoProvider = Provider((ref) => ProductRepository());
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
