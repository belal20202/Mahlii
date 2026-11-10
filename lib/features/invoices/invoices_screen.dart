import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/units.dart';
import '../../models/invoice.dart';
import '../providers.dart';
import 'invoice_detail_screen.dart';

class InvoicesScreen extends ConsumerStatefulWidget {
  const InvoicesScreen({super.key});

  @override
  ConsumerState<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends ConsumerState<InvoicesScreen> {
  String _type = 'sale';
  String _q = '';
  late Future<List<Invoice>> _f;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _f = ref.read(invoiceRepoProvider).list(_type, query: _q);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الفواتير')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'sale', label: Text('مبيعات')),
                ButtonSegment(value: 'purchase', label: Text('مشتريات')),
              ],
              selected: {_type},
              onSelectionChanged: (v) => setState(() {
                _type = v.first;
                _load();
              }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: const InputDecoration(
                  hintText: 'ابحث برقم الفاتورة أو الاسم',
                  prefixIcon: Icon(Icons.search)),
              onChanged: (v) => setState(() {
                _q = v;
                _load();
              }),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Invoice>>(
              future: _f,
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Center(child: Text('تعذر تحميل الفواتير'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snap.data!;
                if (list.isEmpty) {
                  return const Center(child: Text('لا توجد فواتير'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final inv = list[i];
                    final returned = inv.status == 'returned';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        onTap: () async {
                          await Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => InvoiceDetailScreen(invoice: inv)));
                          setState(_load);
                        },
                        title: Text(inv.number,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700)),
                        subtitle: Text(
                            '${fmtDateTime(inv.createdAt)}${inv.party == null ? '' : '  •  ${inv.party}'}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(iqd(inv.total),
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: returned
                                        ? AppColors.danger
                                        : AppColors.emerald)),
                            if (returned)
                              const Text('مرتجعة',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.danger)),
                          ],
                        ),
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
