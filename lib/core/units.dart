/// القطعة هي وحدة التخزين الأساسية. كل التحويلات تتم من هنا فقط.
class Units {
  static int toPieces({
    required int cartons,
    required int pieces,
    required int perCarton,
  }) {
    final per = perCarton < 1 ? 1 : perCarton;
    return cartons * per + pieces;
  }

  /// مثال: 91 قطعة، 12 بالكارتون => "7 كراتين و7 قطع"
  static String format(int totalPieces, int perCarton) {
    final per = perCarton < 1 ? 1 : perCarton;
    if (per == 1) return '$totalPieces قطعة';
    final c = totalPieces ~/ per;
    final p = totalPieces % per;
    if (c == 0) return '$p قطعة';
    if (p == 0) return '$c كرتون';
    return '$c كرتون و$p قطعة';
  }
}

String iqd(num value) {
  final s = value.round().abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return '${value < 0 ? '-' : ''}$buf د.ع';
}
