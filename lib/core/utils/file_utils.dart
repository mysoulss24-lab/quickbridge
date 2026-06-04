import 'dart:io';
import 'package:mime/mime.dart';
import '../constants/constants.dart';

class FileUtils {
  /// Validates a file's extension, size, and MIME type.
  /// Returns null if valid, or a descriptive error message if invalid.
  static String? validateFile(File file) {
    if (!file.existsSync()) {
      return 'File does not exist.';
    }

    // 1. Validate Size (Limit: 200 MB)
    final int size = file.lengthSync();
    if (size > AppConstants.maxFileSizeBytes) {
      final double mbSize = size / (1024 * 1024);
      return 'File is too large (${mbSize.toStringAsFixed(1)} MB). Maximum limit is 200 MB.';
    }

    // 2. Validate Extension
    final String path = file.path.toLowerCase();
    final String extension = path.split('.').last;
    if (!AppConstants.allowedExtensions.contains(extension)) {
      return 'Unsupported file type (. $extension). Only PDF, DOC, DOCX, JPG, JPEG, and PNG files are allowed.';
    }

    // 3. Validate MIME Type
    final String? mimeType = lookupMimeType(file.path);
    if (mimeType == null) {
      return 'Unable to determine file format.';
    }

    final String? expectedMimeType = AppConstants.allowedMimeTypes[extension];
    if (expectedMimeType == null || mimeType != expectedMimeType) {
      // Allow general image type compatibility if extension matches
      if (extension == 'jpg' || extension == 'jpeg' || extension == 'png') {
        if (mimeType.startsWith('image/')) {
          return null; // Accept standard image types
        }
      }
      return 'File content does not match its file extension (detected MIME: $mimeType).';
    }

    return null; // Valid file
  }

  /// Helper to format file sizes nicely
  static String formatBytes(int bytes, {int decimals = 2}) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(decimals)} ${suffixes[i]}';
  }
}
