import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/units.dart';
import '../../models/invoice.dart';
import '../auth/auth_providers.dart';
import '../permissions.dart';
import '../providers.dart';

class InvoiceDetailScreen extends ConsumerStatefulWidget {
  final Invoice invoice;
  const InvoiceDetailScreen({super.key, required this.invoice});

  @override
  ConsumerState<InvoiceDetailScreen> createState() =>
      _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends ConsumerState<InvoiceDetailScreen> {
  late final Future<List<InvoiceItem>> _items;

  @override
  void initState() {
    super.initState();
    _items = ref.read(invoiceRepoProvider).items(widget.invoice.id);
  }

  void _msg(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _return() async {
    final s = ref.read(bootProvider).valueOrNull?.session;
    if (!canSell(s)) {
      _msg('ليس لديك صلاحية الإرجاع');
      return;
    }
    if (!canWriteNow(ref)) {
      _msg(kExpiredMsg);
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إرجاع الفاتورة'),
        content: const Text(
            'سيتم إرجاع كل منتجات الفاتورة إلى المخزون وتصبح الفاتورة مرتجعة. هل تريد المتابعة؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('إرجاع')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(invoiceRepoProvider)
          .returnSale(widget.invoice.id, s!.userName);
      refreshData(ref);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      _msg('تعذر إرجاع الفاتورة');
    }
  }

  @override
  Widget build(BuildContext context) {
    final inv = widget.invoice;
    final s = ref.watch(bootProvider).valueOrNull?.session;
    Widget row(String k, String v, {Color? color, bool bold = false}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Expanded(child: Text(k, style: const TextStyle(color: Colors.grey))),
            Text(v,
                style: TextStyle(
                    color: color,
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
          ]),
        );

    return Scaffold(
      appBar: AppBar(title: Text(inv.number)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                if (inv.status == 'returned')
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text('فاتورة مرتجعة',
                        style: TextStyle(
                            color: AppColors.danger,
                            fontWeight: FontWeight.w800)),
                  ),
                row('التاريخ', fmtDateTime(inv.createdAt)),
                if (inv.userName != null) row('الموظف', inv.userName!),
                row('طريقة الدفع', 'نقدي'),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<InvoiceItem>>(
            future: _items,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()));
              }
              return Card(
                child: Column(children: [
                  for (final it in snap.data!)
                    ListTile(
                      title: Text(it.name),
                      subtitle: Text(
                          '${it.qty} ${it.unit == 'carton' ? 'كرتون' : 'قطعة'} × ${iqd(it.unitPrice)}'),
                      trailing: Text(iqd(it.total),
                          style:
                              const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                ]),
              );
            },
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                row('المجموع', iqd(inv.subtotal)),
                row('الخصم', iqd(inv.discount)),
                row('الإجمالي', iqd(inv.total),
                    bold: true, color: AppColors.emerald),
              ]),
            ),
          ),
          if (inv.status == 'completed' && canSell(s)) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _return,
              icon: const Icon(Icons.assignment_return_outlined),
              label: const Text('إرجاع الفاتورة'),
            ),
          ],
        ],
      ),
    );
  }
}
