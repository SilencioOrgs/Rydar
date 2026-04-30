import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageUtils {
  const ImageUtils._();

  static Future<String> saveRideCardBytes(
    Uint8List bytes,
    String rideId,
  ) async {
    final directory = await _ensureRydarDirectory();
    final path = p.join(directory.path, 'rydar_card_$rideId.png');
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    return path;
  }

  static Future<String> copyPhotoToRydarDirectory(
    String sourcePath,
    String rideId,
  ) async {
    final directory = await _ensureRydarDirectory();
    final extension = p.extension(sourcePath).isEmpty
        ? '.jpg'
        : p.extension(sourcePath);
    final path = p.join(directory.path, 'rydar_photo_$rideId$extension');
    await File(sourcePath).copy(path);
    return path;
  }

  static Future<Directory> _ensureRydarDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(docs.path, 'rydar'));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }
}
