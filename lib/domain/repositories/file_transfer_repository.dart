import 'dart:io';
import '../models/file_metadata_model.dart';

abstract class FileTransferRepository {
  /// Uploads a file to Firebase Storage and writes metadata to Firestore.
  /// Reports progress via onProgress callback: (bytesTransferred, totalBytes).
  Future<void> uploadFile({
    required String pairId,
    required File file,
    required String uploaderDevice,
    required Function(int bytesTransferred, int totalBytes) onProgress,
  });

  /// Downloads a file from Firebase Storage.
  /// Reports progress via onProgress callback.
  Future<File> downloadFile({
    required String storagePath,
    required String fileName,
    required Function(int bytesTransferred, int totalBytes) onProgress,
  });

  /// Deletes file from Storage and removes metadata from Firestore.
  Future<void> deleteFile({
    required String pairId,
    required String fileId,
    required String storagePath,
  });

  /// Lists all files in the current paired session.
  Stream<List<FileMetadataModel>> watchTransferredFiles(String pairId);

  /// Performs client-side validation check and cleanup of expired files.
  Future<void> runLocalCleanupSweep(String pairId, int? cleanupHours);
}
