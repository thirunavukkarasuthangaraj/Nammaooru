import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'logger.dart';

/// Thrown when a picked image can't be compressed small enough to upload.
/// toString() returns the plain message so it reads cleanly in a SnackBar,
/// without Dart's default "Exception: " prefix.
class ImageTooLargeException implements Exception {
  final String message;
  ImageTooLargeException(this.message);
  @override
  String toString() => message;
}

class ImageCompressor {
  // Backend rejects uploads over 10MB (spring.servlet.multipart.max-file-size).
  // Stay well under that so a rejection never reaches the user as a mystery upload failure.
  static const int _maxUploadBytes = 8 * 1024 * 1024;

  /// Compress an XFile image and return a new XFile with compressed data.
  /// Target: under 1MB, max 1280px width/height, quality 70%.
  ///
  /// Some OEM builds fail native compression silently or barely shrink the
  /// image, which used to fall through to an oversized (or original,
  /// uncompressed) file that the backend's 10MB limit then rejected with no
  /// clear reason on the device — this retries harder and, if it truly can't
  /// get under the limit, throws instead of uploading a file doomed to fail.
  static Future<XFile> compressXFile(XFile file, {int quality = 70, int maxDimension = 1280}) async {
    final fileSize = await file.length();
    Logger.i('Original image size: ${(fileSize / 1024).toStringAsFixed(0)} KB', 'IMAGE_COMPRESS');

    // Skip compression for small files (under 500KB)
    if (fileSize < 500 * 1024) {
      Logger.i('Image already small, skipping compression', 'IMAGE_COMPRESS');
      return file;
    }

    XFile? best;
    // Escalating passes: if a pass fails or isn't small enough, retry with a
    // smaller target instead of accepting whatever came out (or the original).
    final passes = [
      (quality: quality, maxDimension: maxDimension),
      (quality: 50, maxDimension: 1024),
      (quality: 35, maxDimension: 720),
    ];

    for (final pass in passes) {
      try {
        final result = await FlutterImageCompress.compressAndGetFile(
          file.path,
          await _getTempPath(),
          quality: pass.quality,
          minWidth: pass.maxDimension,
          minHeight: pass.maxDimension,
          format: CompressFormat.jpeg,
        );
        if (result == null) {
          Logger.w('Compression pass returned null (quality=${pass.quality})', 'IMAGE_COMPRESS');
          continue;
        }
        final compressedSize = await result.length();
        Logger.i(
          'Compressed: ${(fileSize / 1024).toStringAsFixed(0)} KB -> ${(compressedSize / 1024).toStringAsFixed(0)} KB '
          '(quality=${pass.quality})',
          'IMAGE_COMPRESS',
        );
        best = result;
        if (compressedSize <= _maxUploadBytes) {
          return result;
        }
      } catch (e) {
        Logger.e('Compression pass failed (quality=${pass.quality})', 'IMAGE_COMPRESS', e);
      }
    }

    // Every pass either failed or stayed too large — surface a clear,
    // actionable error instead of silently uploading a file the server will
    // reject anyway.
    if (best != null) {
      return best;
    }
    throw ImageTooLargeException(
        'Image too large (${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB). Please choose a smaller photo.');
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
