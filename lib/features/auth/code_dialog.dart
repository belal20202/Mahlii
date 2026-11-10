import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// يُعرض الرمز مرة واحدة فقط، ولا يُحفظ بعدها إلا مشفراً.
Future<void> showCodeDialog(BuildContext context, String code) {
  return showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('رمز التسجيل'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SelectableText(
            code,
            textDirection: TextDirection.ltr,
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 2),
          ),
          const SizedBox(height: 10),
          const Text(
            'انسخه وأرسله الآن. لا يمكن عرضه مرة أخرى، ويُستخدم مرة واحدة.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Clipboard.setData(ClipboardData(text: code)),
          child: const Text('نسخ'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('تم'),
        ),
      ],
    ),
  );
}
