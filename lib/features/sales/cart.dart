import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/invoice.dart';
import '../../models/product.dart';

class CartNotifier extends StateNotifier<List<CartLine>> {
  CartNotifier() : super(const []);

  /// يرجع false إذا كانت الكمية المطلوبة أكبر من المتوفر.
  bool add(Product p) {
    final idx = state.indexWhere((l) => l.product.id == p.id);
    final current = idx >= 0 ? state[idx].qty : 0;
    if (current + 1 > p.qtyPieces) return false;
    if (idx >= 0) {
      state = [...state]..[idx] = state[idx].copyWith(qty: current + 1);
    } else {
      state = [...state, CartLine(product: p, qty: 1)];
    }
    return true;
  }

  bool setQty(int i, int qty) {
    if (qty < 1) return false;
    if (qty > state[i].product.qtyPieces) return false;
    state = [...state]..[i] = state[i].copyWith(qty: qty);
    return true;
  }

  void remove(int i) => state = [...state]..removeAt(i);

  void clear() => state = const [];
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartLine>>(
    (ref) => CartNotifier());
