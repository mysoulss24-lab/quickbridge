import 'dart:async';
import 'dart:io';
import 'package:uuid/uuid.dart';
import '../../domain/models/file_metadata_model.dart';
import '../../domain/repositories/file_transfer_repository.dart';
import 'mock_pairing_repository.dart';

class MockFileTransferRepository implements FileTransferRepository {
  static final _filesController = BehaviorSubject<List<FileMetadataModel>>([]);
  final Uuid _uuid = const Uuid();

  @override
  Future<void> uploadFile({
    required String pairId,
    required File file,
    required String uploaderDevice,
    required Function(int bytesTransferred, int totalBytes) onProgress,
  }) async {
    final int totalBytes = file.lengthSync();
    const int steps = 15;
    final int stepBytes = (totalBytes / steps).ceil();

    for (int i = 0; i <= steps; i++) {
      await Future.delayed(const Duration(milliseconds: 150));
      int bytes = i * stepBytes;
      if (bytes > totalBytes) bytes = totalBytes;
      onProgress(bytes, totalBytes);
    }

    final String fileId = _uuid.v4();
    final String fileName = file.path.split(Platform.isWindows ? '\\' : '/').last;
    final String fileExtension = fileName.split('.').last.toLowerCase();
    
    final metadata = FileMetadataModel(
      fileId: fileId,
      fileName: fileName,
      fileSize: totalBytes,
      uploadTime: DateTime.now(),
      uploaderDevice: uploaderDevice,
      downloadStatus: 'uploaded',
      storagePath: 'mock_path/$pairId/files/$fileId.$fileExtension',
      fileType: fileExtension,
    );

    final currentFiles = List<FileMetadataModel>.from(_filesController.value);
    currentFiles.insert(0, metadata);
    _filesController.add(currentFiles);
  }

  @override
  Future<File> downloadFile({
    required String storagePath,
    required String fileName,
    required Function(int bytesTransferred, int totalBytes) onProgress,
  }) async {
    const int totalBytes = 50 * 1024 * 1024; // Mock 50 MB
    const int steps = 15;
    final int stepBytes = (totalBytes / steps).ceil();

    for (int i = 0; i <= steps; i++) {
      await Future.delayed(const Duration(milliseconds: 150));
      int bytes = i * stepBytes;
      if (bytes > totalBytes) bytes = totalBytes;
      onProgress(bytes, totalBytes);
    }

    // Return the executable or any dummy file
    return File(Platform.isWindows ? 'quickbridge.exe' : 'mock_file');
  }

  @override
  Future<void> deleteFile({
    required String pairId,
    required String fileId,
    required String storagePath,
  }) async {
    final currentFiles = List<FileMetadataModel>.from(_filesController.value);
    currentFiles.removeWhere((file) => file.fileId == fileId);
    _filesController.add(currentFiles);
  }

  @override
  Stream<List<FileMetadataModel>> watchTransferredFiles(String pairId) {
    // If empty list, add a mock pre-existing file from the other device to make the UI look populated and interactive
    if (_filesController.value.isEmpty) {
      final mockFile = FileMetadataModel(
        fileId: 'mock_prev_file_1',
        fileName: 'Project_Design_Specification.pdf',
        fileSize: 45 * 1024 * 1024,
        uploadTime: DateTime.now().subtract(const Duration(minutes: 10)),
        uploaderDevice: Platform.isAndroid ? 'Mock Windows PC' : 'Mock Galaxy S24 Ultra',
        downloadStatus: 'uploaded',
        storagePath: 'mock_path/files/mock_prev_file_1.pdf',
        fileType: 'pdf',
      );
      _filesController.add([mockFile]);
    }
    return _filesController.stream;
  }

  @override
  Future<void> runLocalCleanupSweep(String pairId, int? cleanupHours) async {
    // No-op
  }
}
