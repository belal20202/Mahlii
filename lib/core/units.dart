String iqd(num value) {
  final s = value.round().abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return '${value < 0 ? '-' : ''}$buf د.ع';
}
