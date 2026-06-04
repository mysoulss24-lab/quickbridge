import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../domain/models/file_metadata_model.dart';
import '../../domain/repositories/file_transfer_repository.dart';
import '../../data/repositories/file_transfer_repository_impl.dart';
import '../../core/utils/file_utils.dart';
import '../../core/utils/speed_calculator.dart';
import '../../core/services/notification_service.dart';
import 'pairing_provider.dart';
import 'settings_provider.dart';

// Transfer status tracker class
class TransferProgress {
  final String fileId;
  final String fileName;
  final int totalBytes;
  final int bytesTransferred;
  final double speedBytesPerSecond;
  final String formattedSpeed;
  final String formattedRemainingTime;
  final double progressPercent; // 0.0 to 1.0
  final bool isUpload; // true = upload, false = download

  TransferProgress({
    required this.fileId,
    required this.fileName,
    required this.totalBytes,
    required this.bytesTransferred,
    required this.speedBytesPerSecond,
    required this.formattedSpeed,
    required this.formattedRemainingTime,
    required this.progressPercent,
    required this.isUpload,
  });

  TransferProgress copyWith({
    int? bytesTransferred,
    double? speedBytesPerSecond,
    String? formattedSpeed,
    String? formattedRemainingTime,
    double? progressPercent,
  }) {
    return TransferProgress(
      fileId: fileId,
      fileName: fileName,
      totalBytes: totalBytes,
      bytesTransferred: bytesTransferred ?? this.bytesTransferred,
      speedBytesPerSecond: speedBytesPerSecond ?? this.speedBytesPerSecond,
      formattedSpeed: formattedSpeed ?? this.formattedSpeed,
      formattedRemainingTime: formattedRemainingTime ?? this.formattedRemainingTime,
      progressPercent: progressPercent ?? this.progressPercent,
      isUpload: isUpload,
    );
  }
}

class TransferState {
  final List<FileMetadataModel> files;
  final Map<String, TransferProgress> activeTransfers; // fileId -> progress details
  final bool isOffline;
  final String? errorMessage;
  final List<Map<String, dynamic>> retryQueue; // Queue for retrying failed uploads/downloads

  TransferState({
    this.files = const [],
    this.activeTransfers = const {},
    this.isOffline = false,
    this.errorMessage,
    this.retryQueue = const [],
  });

  TransferState copyWith({
    List<FileMetadataModel>? files,
    Map<String, TransferProgress>? activeTransfers,
    bool? isOffline,
    String? errorMessage,
    List<Map<String, dynamic>>? retryQueue,
  }) {
    return TransferState(
      files: files ?? this.files,
      activeTransfers: activeTransfers ?? this.activeTransfers,
      isOffline: isOffline ?? this.isOffline,
      errorMessage: errorMessage,
      retryQueue: retryQueue ?? this.retryQueue,
    );
  }
}

class TransferNotifier extends StateNotifier<TransferState> {
  final FileTransferRepository _repository = FileTransferRepositoryImpl();
  final NotificationService _notificationService = NotificationService();
  StreamSubscription<List<FileMetadataModel>>? _filesSubscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final Ref _ref;
  
  // Track seen files to prevent notifying for pre-existing files
  final Set<String> _notifiedFiles = {};

  TransferNotifier(this._ref) : super(TransferState()) {
    _initConnectivityListener();
    _initPairingListener();
  }

  void _initConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final isOffline = results.isEmpty || results.contains(ConnectivityResult.none);
      state = state.copyWith(isOffline: isOffline);
      
      if (!isOffline && state.retryQueue.isNotEmpty) {
        _processRetryQueue();
      }
    });
  }

  void _initPairingListener() {
    // Listen to pairing changes
    _ref.listen(pairingProvider, (previous, next) {
      final pairId = next.activePairId;
      if (pairId != null) {
        _startListeningToFiles(pairId);
        // Trigger background cleanup sweep when paired
        final cleanupHours = _ref.read(settingsProvider).cleanupHours;
        _repository.runLocalCleanupSweep(pairId, cleanupHours);
      } else {
        _stopListeningToFiles();
      }
    });
  }

  void _startListeningToFiles(String pairId) {
    _filesSubscription?.cancel();
    _filesSubscription = _repository.watchTransferredFiles(pairId).listen((fileList) {
      final bool isFirstLoad = state.files.isEmpty && _notifiedFiles.isEmpty;
      
      // Determine if a new file has arrived (not uploaded by this device)
      if (!isFirstLoad) {
        final localDeviceName = _ref.read(pairingProvider).localDeviceName;
        for (final file in fileList) {
          if (!_notifiedFiles.contains(file.fileId) && file.uploaderDevice != localDeviceName) {
            _notifiedFiles.add(file.fileId);
            _notificationService.showNotification(
              title: 'File Received 📥',
              body: '${file.fileName} (${FileUtils.formatBytes(file.fileSize)}) is ready to download.',
            );
          }
        }
      } else {
        // Mark all existing files as seen so we don't trigger notification for them
        for (final file in fileList) {
          _notifiedFiles.add(file.fileId);
        }
      }

      state = state.copyWith(files: fileList);
    }, onError: (err) {
      state = state.copyWith(errorMessage: err.toString());
    });
  }

  void _stopListeningToFiles() {
    _filesSubscription?.cancel();
    _filesSubscription = null;
    _notifiedFiles.clear();
    state = state.copyWith(files: [], activeTransfers: {}, retryQueue: []);
  }

  /// Initiates uploading a file
  Future<void> shareFile(File file) async {
    final String? pairId = _ref.read(pairingProvider).activePairId;
    if (pairId == null) {
      state = state.copyWith(errorMessage: 'No paired device connected.');
      return;
    }

    // 1. Pre-validation
    final String? validationError = FileUtils.validateFile(file);
    if (validationError != null) {
      state = state.copyWith(errorMessage: validationError);
      return;
    }

    // 2. Queue if offline
    if (state.isOffline) {
      _addToRetryQueue('upload', {'file': file, 'pairId': pairId});
      state = state.copyWith(errorMessage: 'Offline. File upload queued.');
      return;
    }

    final String tempId = 'up_${DateTime.now().millisecondsSinceEpoch}';
    final String fileName = file.path.split(Platform.isWindows ? '\\' : '/').last;
    final speedCalc = SpeedCalculator(totalBytes: file.lengthSync());

    final progressInfo = TransferProgress(
      fileId: tempId,
      fileName: fileName,
      totalBytes: file.lengthSync(),
      bytesTransferred: 0,
      speedBytesPerSecond: 0,
      formattedSpeed: '0 KB/s',
      formattedRemainingTime: 'Calculating...',
      progressPercent: 0.0,
      isUpload: true,
    );

    // Add to active transfers
    final active = Map<String, TransferProgress>.from(state.activeTransfers);
    active[tempId] = progressInfo;
    state = state.copyWith(activeTransfers: active);

    try {
      final localDeviceName = _ref.read(pairingProvider).localDeviceName;
      await _repository.uploadFile(
        pairId: pairId,
        file: file,
        uploaderDevice: localDeviceName,
        onProgress: (bytes, total) {
          final double progress = total > 0 ? bytes / total : 0;
          final updated = state.activeTransfers[tempId]?.copyWith(
            bytesTransferred: bytes,
            speedBytesPerSecond: speedCalc.getBytesPerSecond(bytes),
            formattedSpeed: speedCalc.getFormattedSpeed(bytes),
            formattedRemainingTime: speedCalc.getFormattedRemainingTime(bytes),
            progressPercent: progress,
          );
          if (updated != null) {
            final currentActive = Map<String, TransferProgress>.from(state.activeTransfers);
            currentActive[tempId] = updated;
            state = state.copyWith(activeTransfers: currentActive);
          }
        },
      );

      // Success
      _notificationService.showNotification(
        title: 'Upload Completed! 📤',
        body: '$fileName uploaded successfully.',
      );

      // Remove from active
      final afterSuccessActive = Map<String, TransferProgress>.from(state.activeTransfers);
      afterSuccessActive.remove(tempId);
      state = state.copyWith(activeTransfers: afterSuccessActive);
    } catch (e) {
      // Remove from active and queue
      final afterErrorActive = Map<String, TransferProgress>.from(state.activeTransfers);
      afterErrorActive.remove(tempId);
      state = state.copyWith(activeTransfers: afterErrorActive);
      
      _addToRetryQueue('upload', {'file': file, 'pairId': pairId});
      state = state.copyWith(errorMessage: 'Upload failed: $e. Queued for retry.');
    }
  }

  /// Downloads file from Storage
  Future<void> fetchFile(FileMetadataModel fileMeta) async {
    // Check if offline
    if (state.isOffline) {
      _addToRetryQueue('download', {'metadata': fileMeta});
      state = state.copyWith(errorMessage: 'Offline. Download queued.');
      return;
    }

    final speedCalc = SpeedCalculator(totalBytes: fileMeta.fileSize);
    final String fileId = fileMeta.fileId;

    final progressInfo = TransferProgress(
      fileId: fileId,
      fileName: fileMeta.fileName,
      totalBytes: fileMeta.fileSize,
      bytesTransferred: 0,
      speedBytesPerSecond: 0,
      formattedSpeed: '0 KB/s',
      formattedRemainingTime: 'Calculating...',
      progressPercent: 0.0,
      isUpload: false,
    );

    // Add to active
    final active = Map<String, TransferProgress>.from(state.activeTransfers);
    active[fileId] = progressInfo;
    state = state.copyWith(activeTransfers: active);

    try {
      final downloadedFile = await _repository.downloadFile(
        storagePath: fileMeta.storagePath,
        fileName: fileMeta.fileName,
        onProgress: (bytes, total) {
          final double progress = total > 0 ? bytes / total : 0;
          final updated = state.activeTransfers[fileId]?.copyWith(
            bytesTransferred: bytes,
            speedBytesPerSecond: speedCalc.getBytesPerSecond(bytes),
            formattedSpeed: speedCalc.getFormattedSpeed(bytes),
            formattedRemainingTime: speedCalc.getFormattedRemainingTime(bytes),
            progressPercent: progress,
          );
          if (updated != null) {
            final currentActive = Map<String, TransferProgress>.from(state.activeTransfers);
            currentActive[fileId] = updated;
            state = state.copyWith(activeTransfers: currentActive);
          }
        },
      );

      // Success Notification
      _notificationService.showNotification(
        title: 'Download Completed! 📥',
        body: '${fileMeta.fileName} saved to Downloads.',
      );

      // Remove from active
      final afterSuccessActive = Map<String, TransferProgress>.from(state.activeTransfers);
      afterSuccessActive.remove(fileId);
      state = state.copyWith(activeTransfers: afterSuccessActive);
    } catch (e) {
      // Remove from active and queue
      final afterErrorActive = Map<String, TransferProgress>.from(state.activeTransfers);
      afterErrorActive.remove(fileId);
      state = state.copyWith(activeTransfers: afterErrorActive);

      _addToRetryQueue('download', {'metadata': fileMeta});
      state = state.copyWith(errorMessage: 'Download failed: $e. Queued for retry.');
    }
  }

  /// Deletes a file from both Firestore and Firebase Storage
  Future<void> removeFile(FileMetadataModel fileMeta) async {
    final String? pairId = _ref.read(pairingProvider).activePairId;
    if (pairId == null) return;

    try {
      await _repository.deleteFile(
        pairId: pairId,
        fileId: fileMeta.fileId,
        storagePath: fileMeta.storagePath,
      );

      _notificationService.showNotification(
        title: 'File Deleted 🗑️',
        body: '${fileMeta.fileName} was permanently removed.',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Delete failed: $e');
    }
  }

  void _addToRetryQueue(String type, Map<String, dynamic> data) {
    final queue = List<Map<String, dynamic>>.from(state.retryQueue);
    queue.add({'type': type, 'data': data});
    state = state.copyWith(retryQueue: queue);
  }

  void _processRetryQueue() {
    if (state.isOffline || state.retryQueue.isEmpty) return;

    final queue = List<Map<String, dynamic>>.from(state.retryQueue);
    state = state.copyWith(retryQueue: []); // Clear queue and start executing items

    for (final item in queue) {
      final String type = item['type'];
      final data = item['data'];
      
      if (type == 'upload') {
        shareFile(data['file'] as File);
      } else if (type == 'download') {
        fetchFile(data['metadata'] as FileMetadataModel);
      }
    }
  }

  void clearErrorMessage() {
    state = state.copyWith(errorMessage: null);
  }

  @override
  void dispose() {
    _filesSubscription?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

final transferProvider = StateNotifierProvider<TransferNotifier, TransferState>((ref) {
  return TransferNotifier(ref);
});
