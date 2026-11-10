import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Sfx { scan, added, sold, invoice, error }

/// أصوات هادئة وقصيرة تُولَّد برمجياً (WAV) بدون ملفات خارجية.
class SoundService {
  static bool enabled = true;
  static const _key = 'sound_enabled';
  static final Map<Sfx, Uint8List> _cache = {};

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    enabled = prefs.getBool(_key) ?? true;
    _cache[Sfx.scan] = _wav([(1100, 55)]);
    _cache[Sfx.added] = _wav([(660, 90), (880, 130)]);
    _cache[Sfx.sold] = _wav([(784, 90), (1047, 150)]);
    _cache[Sfx.invoice] = _wav([(523, 90), (659, 90), (784, 140)]);
    _cache[Sfx.error] = _wav([(330, 170)]);
  }

  static Future<void> setEnabled(bool v) async {
    enabled = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, v);
  }

  static Future<void> play(Sfx sfx) async {
    if (!enabled) return;
    final bytes = _cache[sfx];
    if (bytes == null) return;
    try {
      final p = AudioPlayer();
      p.onPlayerComplete.listen((_) => p.dispose());
      await p.play(BytesSource(bytes), volume: 0.5);
    } catch (_) {
      // الصوت ميزة مساندة ولا يجب أن تعطل العمل.
    }
  }

  static Uint8List _wav(List<(double, int)> notes) {
    const rate = 22050;
    final samples = <int>[];
    for (final (freq, ms) in notes) {
      final n = rate * ms ~/ 1000;
      for (var i = 0; i < n; i++) {
        final env = math.sin(math.pi * i / n); // دخول وخروج ناعم
        final v = math.sin(2 * math.pi * freq * i / rate) * env * 0.22;
        samples.add((v * 32767).round());
      }
    }
    final len = samples.length * 2;
    final d = ByteData(44 + len);
    void tag(int o, String t) {
      for (var i = 0; i < 4; i++) {
        d.setUint8(o + i, t.codeUnitAt(i));
      }
    }

    tag(0, 'RIFF');
    d.setUint32(4, 36 + len, Endian.little);
    tag(8, 'WAVE');
    tag(12, 'fmt ');
    d.setUint32(16, 16, Endian.little);
    d.setUint16(20, 1, Endian.little);
    d.setUint16(22, 1, Endian.little);
    d.setUint32(24, rate, Endian.little);
    d.setUint32(28, rate * 2, Endian.little);
    d.setUint16(32, 2, Endian.little);
    d.setUint16(34, 16, Endian.little);
    tag(36, 'data');
    d.setUint32(40, len, Endian.little);
    for (var i = 0; i < samples.length; i++) {
      d.setInt16(44 + i * 2, samples[i], Endian.little);
    }
    return d.buffer.asUint8List();
  }
}
