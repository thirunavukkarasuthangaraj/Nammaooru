import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'logger.dart';

class ImageCompressor {
  /// Compress an XFile image and return a new XFile with compressed data.
  /// Target: under 1MB, max 1280px width/height, quality 70%.
  static Future<XFile> compressXFile(XFile file, {int quality = 70, int maxDimension = 1280}) async {
    try {
      final fileSize = await file.length();
      Logger.i('Original image size: ${(fileSize / 1024).toStringAsFixed(0)} KB', 'IMAGE_COMPRESS');

      // Skip compression for small files (under 500KB)
      if (fileSize < 500 * 1024) {
        Logger.i('Image already small, skipping compression', 'IMAGE_COMPRESS');
        return file;
      }

      final result = await FlutterImageCompress.compressAndGetFile(
        file.path,
        await _getTempPath(),
        quality: quality,
        minWidth: maxDimension,
        minHeight: maxDimension,
        format: CompressFormat.jpeg,
      );

      if (result != null) {
        final compressedSize = await result.length();
        Logger.i(
          'Compressed: ${(fileSize / 1024).toStringAsFixed(0)} KB -> ${(compressedSize / 1024).toStringAsFixed(0)} KB',
          'IMAGE_COMPRESS',
        );
        return result;
      }

      Logger.w('Compression returned null, using original', 'IMAGE_COMPRESS');
      return file;
    } catch (e) {
      Logger.e('Image compression failed, using original', 'IMAGE_COMPRESS', e);
      return file;
    }
  }

  /// Compress a list of XFile images
  static Future<List<XFile>> compressMultiple(List<XFile> files, {int quality = 70, int maxDimension = 1280}) async {
    final compressed = <XFile>[];
    for (final file in files) {
      compressed.add(await compressXFile(file, quality: quality, maxDimension: maxDimension));
    }
    return compressed;
  }

  /// Always write into the app's own sandboxed temp directory — the source
  /// file's own folder (e.g. a Photo Picker-resolved path) isn't reliably
  /// writable by the app, which caused silent per-device compression
  /// failures once broad media permissions were dropped for Play Store
  /// compliance.
  static Future<String> _getTempPath() async {
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${dir.path}/compressed_$timestamp.jpg';
  }
}
