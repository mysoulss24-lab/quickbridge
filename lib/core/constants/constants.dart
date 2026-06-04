class AppConstants {
  // File size limit in bytes (200 MB)
  static const int maxFileSizeBytes = 200 * 1024 * 1024;

  // Allowed file extensions
  static const List<String> allowedExtensions = [
    'pdf',
    'doc',
    'docx',
    'jpg',
    'jpeg',
    'png',
  ];

  // Allowed MIME types map
  static const Map<String, String> allowedMimeTypes = {
    'pdf': 'application/pdf',
    'doc': 'application/msword',
    'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
  };

  // Firestore Collection Names
  static const String pairingsCollection = 'pairings';
  static const String transfersSubcollection = 'transfers';

  // Storage path prefix
  static const String storagePathPrefix = 'pairings';

  // Configurable cleanup options in hours
  static const Map<String, int?> cleanupOptions = {
    '24 Hours': 24,
    '3 Days': 72,
    '7 Days': 168,
    'Never': null,
  };
}
