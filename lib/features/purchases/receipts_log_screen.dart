import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/receipt.dart';
import '../providers.dart';

/// سجل المشتريات والإدخال: إدخالات البضاعة والمنتجات الجديدة وتعديلات الكميات
class ReceiptsLogScreen extends ConsumerStatefulWidget {
  const ReceiptsLogScreen({super.key});

  @override
  ConsumerState<ReceiptsLogScreen> createState() => _ReceiptsLogScreenState();
}

class _ReceiptsLogScreenState extends ConsumerState<ReceiptsLogScreen> {
  late final Future<List<LogEntry>> _f;

  @override
  void initState() {
    super.initState();
    _f = ref.read(receiptRepoProvider).log();
  }

  IconData _icon(String kind) {
    switch (kind) {
      case 'receipt':
        return Icons.inventory_2_outlined;
      case 'new':
        return Icons.add_box_outlined;
      default:
        return Icons.tune;
    }
  }

  void _showItems(LogEntry e) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => FutureBuilder<List<ReceiptItem>>(
        future: ref.read(receiptRepoProvider).items(e.receiptId!),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()));
          }
          return ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(16),
            children: [
              Text(e.title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              for (final it in snap.data!)
                ListTile(
                  title: Text(it.name),
                  trailing: Text('+${it.qty} قطعة',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.emerald)),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سجل المشتريات والإدخال')),
      body: FutureBuilder<List<LogEntry>>(
        future: _f,
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(child: Text('تعذر تحميل السجل'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data!;
          if (list.isEmpty) return const Center(child: Text('السجل فارغ'));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final e = list[i];
              final neg = e.pieces < 0;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  onTap: e.receiptId == null ? null : () => _showItems(e),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.mint,
                    child: Icon(_icon(e.kind), color: AppColors.emerald),
                  ),
                  title: Text(e.title,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                      '${e.subtitle}\n${fmtDateTime(e.time)}${e.userName == null ? '' : '  •  ${e.userName}'}'),
                  isThreeLine: true,
                  trailing: Text(
                    '${neg ? '' : '+'}${e.pieces}',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: neg ? AppColors.danger : AppColors.emerald),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
