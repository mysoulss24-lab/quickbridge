import 'dart:io';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/constants.dart';
import '../../domain/models/file_metadata_model.dart';
import '../../domain/repositories/file_transfer_repository.dart';

class FileTransferRepositoryImpl implements FileTransferRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  @override
  Future<void> uploadFile({
    required String pairId,
    required File file,
    required String uploaderDevice,
    required Function(int bytesTransferred, int totalBytes) onProgress,
  }) async {
    final String fileId = _uuid.v4();
    final String fileName = file.path.split(Platform.isWindows ? '\\' : '/').last;
    final String fileExtension = fileName.split('.').last.toLowerCase();
    final String storagePath = '${AppConstants.storagePathPrefix}/$pairId/files/$fileId.$fileExtension';

    // 1. Reference in Firebase Storage
    final Reference ref = _storage.ref().child(storagePath);

    // 2. Upload with uploadTask to track progress
    final UploadTask uploadTask = ref.putFile(file);

    final completer = Completer<void>();

    final StreamSubscription<TaskSnapshot> subscription = uploadTask.snapshotEvents.listen(
      (snapshot) {
        onProgress(snapshot.bytesTransferred, snapshot.totalBytes);
      },
      onError: (e) {
        completer.completeError(e);
      },
    );

    try {
      await uploadTask;
      subscription.cancel();
      
      // 3. Write metadata to Firestore under killings subcollection
      final FileMetadataModel metadata = FileMetadataModel(
        fileId: fileId,
        fileName: fileName,
        fileSize: file.lengthSync(),
        uploadTime: DateTime.now(),
        uploaderDevice: uploaderDevice,
        downloadStatus: 'uploaded',
        storagePath: storagePath,
        fileType: fileExtension,
      );

      await _firestore
          .collection(AppConstants.pairingsCollection)
          .doc(pairId)
          .collection(AppConstants.transfersSubcollection)
          .doc(fileId)
          .set(metadata.toMap());
          
      completer.complete();
    } catch (e) {
      subscription.cancel();
      completer.completeError(e);
    }

    return completer.future;
  }

  @override
  Future<File> downloadFile({
    required String storagePath,
    required String fileName,
    required Function(int bytesTransferred, int totalBytes) onProgress,
  }) async {
    final Reference ref = _storage.ref().child(storagePath);
    final String downloadUrl = await ref.getDownloadURL();

    // 1. Get destination directory
    Directory? downloadDir;
    if (Platform.isAndroid) {
      downloadDir = Directory('/storage/emulated/0/Download');
      if (!downloadDir.existsSync()) {
        downloadDir = await getExternalStorageDirectory();
      }
    } else if (Platform.isWindows) {
      final String userProfile = Platform.environment['USERPROFILE'] ?? '';
      downloadDir = Directory('$userProfile\\Downloads');
      if (!downloadDir.existsSync()) {
        downloadDir = await getApplicationDocumentsDirectory();
      }
    } else {
      downloadDir = await getApplicationDocumentsDirectory();
    }

    final File destinationFile = File('${downloadDir!.path}/$fileName');
    
    // De-conflict file name if file already exists
    int counter = 1;
    String finalPath = destinationFile.path;
    final String baseName = fileName.substring(0, fileName.lastIndexOf('.'));
    final String extension = fileName.substring(fileName.lastIndexOf('.'));
    
    while (File(finalPath).existsSync()) {
      finalPath = '${downloadDir.path}/${baseName}_($counter)$extension';
      counter++;
    }
    
    final File finalFile = File(finalPath);

    // 2. Download via HTTP Client to report progress
    final HttpClient client = HttpClient();
    final HttpClientRequest request = await client.getUrl(Uri.parse(downloadUrl));
    final HttpClientResponse response = await request.close();

    if (response.statusCode != 200) {
      throw HttpException('Failed to download file: HTTP ${response.statusCode}');
    }

    final int totalBytes = response.contentLength;
    int bytesDownloaded = 0;
    
    final IOSink fileSink = finalFile.openWrite();

    final completer = Completer<File>();

    response.listen(
      (List<int> chunk) {
        fileSink.add(chunk);
        bytesDownloaded += chunk.length;
        onProgress(bytesDownloaded, totalBytes);
      },
      onDone: () async {
        await fileSink.flush();
        await fileSink.close();
        completer.complete(finalFile);
      },
      onError: (e) async {
        await fileSink.close();
        if (finalFile.existsSync()) {
          finalFile.deleteSync();
        }
        completer.completeError(e);
      },
      cancelOnError: true,
    );

    return completer.future;
  }

  @override
  Future<void> deleteFile({
    required String pairId,
    required String fileId,
    required String storagePath,
  }) async {
    // 1. Delete from Firebase Storage
    try {
      await _storage.ref().child(storagePath).delete();
    } catch (e) {
      // If file doesn't exist on storage, ignore and proceed to delete firestore doc
      if (!e.toString().contains('object-not-found')) {
        rethrow;
      }
    }

    // 2. Delete Firestore doc metadata
    await _firestore
        .collection(AppConstants.pairingsCollection)
        .doc(pairId)
        .collection(AppConstants.transfersSubcollection)
        .doc(fileId)
        .delete();
  }

  @override
  Stream<List<FileMetadataModel>> watchTransferredFiles(String pairId) {
    return _firestore
        .collection(AppConstants.pairingsCollection)
        .doc(pairId)
        .collection(AppConstants.transfersSubcollection)
        .orderBy('uploadTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FileMetadataModel.fromMap(doc.data()))
          .toList();
    });
  }

  @override
  Future<void> runLocalCleanupSweep(String pairId, int? cleanupHours) async {
    if (cleanupHours == null) return; // 'Never'

    final threshold = DateTime.now().subtract(Duration(hours: cleanupHours));
    
    final QuerySnapshot query = await _firestore
        .collection(AppConstants.pairingsCollection)
        .doc(pairId)
        .collection(AppConstants.transfersSubcollection)
        .where('uploadTime', isLessThan: Timestamp.fromDate(threshold))
        .get();

    for (var doc in query.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final String fileId = data['fileId'] ?? '';
      final String storagePath = data['storagePath'] ?? '';
      if (fileId.isNotEmpty && storagePath.isNotEmpty) {
        try {
          await deleteFile(pairId: pairId, fileId: fileId, storagePath: storagePath);
        } catch (e) {
          // log error and continue
          print('Local Cleanup Sweep failed for file $fileId: $e');
        }
      }
    }
  }
}
