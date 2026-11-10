import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/invoice.dart';
import '../../models/product.dart';

class CartNotifier extends StateNotifier<List<CartLine>> {
  CartNotifier() : super(const []);

  int _piecesOf(int productId, {int? skip}) {
    var n = 0;
    for (var i = 0; i < state.length; i++) {
      if (i == skip) continue;
      if (state[i].product.id == productId) n += state[i].pieces;
    }
    return n;
  }

  /// يرجع false إذا كانت الكمية المطلوبة أكبر من المتوفر.
  bool add(Product p, {bool carton = false}) {
    final per = p.piecesPerCarton < 1 ? 1 : p.piecesPerCarton;
    final addPieces = carton ? per : 1;
    if (_piecesOf(p.id!) + addPieces > p.qtyPieces) return false;
    final idx =
        state.indexWhere((l) => l.product.id == p.id && l.carton == carton);
    if (idx >= 0) {
      final l = state[idx];
      state = [...state]..[idx] = l.copyWith(qty: l.qty + 1);
    } else {
      state = [
        ...state,
        CartLine(
          product: p,
          qty: 1,
          carton: carton,
          unitPrice: carton ? p.salePrice * per : p.salePrice,
        ),
      ];
    }
    return true;
  }

  bool setQty(int i, int qty) {
    if (qty < 1) return false;
    final l = state[i];
    if (_piecesOf(l.product.id!, skip: i) + qty * l.perUnit >
        l.product.qtyPieces) {
      return false;
    }
    state = [...state]..[i] = l.copyWith(qty: qty);
    return true;
  }

  bool switchUnit(int i) {
    final n = state[i].switchedUnit();
    if (_piecesOf(n.product.id!, skip: i) + n.pieces > n.product.qtyPieces) {
      return false;
    }
    state = [...state]..[i] = n;
    return true;
  }

  void remove(int i) => state = [...state]..removeAt(i);

  void clear() => state = const [];
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartLine>>(
    (ref) => CartNotifier());
