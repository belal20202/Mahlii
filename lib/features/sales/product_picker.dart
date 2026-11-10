import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/units.dart';
import '../../models/product.dart';
import '../providers.dart';

Future<Product?> pickProduct(BuildContext context) {
  return showModalBottomSheet<Product>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _PickerSheet(),
  );
}

class _PickerSheet extends ConsumerStatefulWidget {
  const _PickerSheet();

  @override
  ConsumerState<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends ConsumerState<_PickerSheet> {
  late Future<List<Product>> _f;

  @override
  void initState() {
    super.initState();
    _f = ref.read(repoProvider).search('', limit: 60);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                autofocus: true,
                decoration: const InputDecoration(
                    hintText: 'ابحث بالاسم أو الباركود',
                    prefixIcon: Icon(Icons.search)),
                onChanged: (q) => setState(
                    () => _f = ref.read(repoProvider).search(q, limit: 60)),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Product>>(
                future: _f,
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final list = snap.data!;
                  if (list.isEmpty) {
                    return const Center(child: Text('لا توجد نتائج'));
                  }
                  return ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final p = list[i];
                      return ListTile(
                        title: Text(p.name),
                        subtitle: Text(
                            'المتوفر: ${Units.format(p.qtyPieces, p.piecesPerCarton)}'),
                        trailing: Text(iqd(p.salePrice)),
                        onTap: () => Navigator.pop(context, p),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
