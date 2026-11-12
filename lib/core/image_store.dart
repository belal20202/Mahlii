import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// صور المنتجات تُحفظ مضغوطة على الهاتف.
class ImageStore {
  static Future<String?> pick(ImageSource source) async {
    final x = await ImagePicker().pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 70,
    );
    if (x == null) return null;
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(dir.path, 'product_images'));
    if (!await folder.exists()) await folder.create(recursive: true);
    final dest =
        p.join(folder.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');
    await File(x.path).copy(dest);
    return dest;
  }

  static Future<void> delete(String? path) async {
    if (path == null) return;
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }
}
