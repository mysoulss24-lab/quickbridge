import 'package:cloud_firestore/cloud_firestore.dart';

class FileMetadataModel {
  final String fileId;
  final String fileName;
  final int fileSize;
  final DateTime uploadTime;
  final String uploaderDevice; // e.g. 'android', 'windows'
  final String downloadStatus; // 'uploaded', 'downloading', 'downloaded', 'failed'
  final String storagePath;
  final String fileType; // pdf, doc, docx, jpg, jpeg, png

  FileMetadataModel({
    required this.fileId,
    required this.fileName,
    required this.fileSize,
    required this.uploadTime,
    required this.uploaderDevice,
    required this.downloadStatus,
    required this.storagePath,
    required this.fileType,
  });

  Map<String, dynamic> toMap() {
    return {
      'fileId': fileId,
      'fileName': fileName,
      'fileSize': fileSize,
      'uploadTime': Timestamp.fromDate(uploadTime),
      'uploaderDevice': uploaderDevice,
      'downloadStatus': downloadStatus,
      'storagePath': storagePath,
      'fileType': fileType,
    };
  }

  factory FileMetadataModel.fromMap(Map<String, dynamic> map) {
    return FileMetadataModel(
      fileId: map['fileId'] ?? '',
      fileName: map['fileName'] ?? '',
      fileSize: map['fileSize'] ?? 0,
      uploadTime: map['uploadTime'] != null
          ? (map['uploadTime'] as Timestamp).toDate()
          : DateTime.now(),
      uploaderDevice: map['uploaderDevice'] ?? '',
      downloadStatus: map['downloadStatus'] ?? 'uploaded',
      storagePath: map['storagePath'] ?? '',
      fileType: map['fileType'] ?? '',
    );
  }

  FileMetadataModel copyWith({
    String? fileId,
    String? fileName,
    int? fileSize,
    DateTime? uploadTime,
    String? uploaderDevice,
    String? downloadStatus,
    String? storagePath,
    String? fileType,
  }) {
    return FileMetadataModel(
      fileId: fileId ?? this.fileId,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      uploadTime: uploadTime ?? this.uploadTime,
      uploaderDevice: uploaderDevice ?? this.uploaderDevice,
      downloadStatus: downloadStatus ?? this.downloadStatus,
      storagePath: storagePath ?? this.storagePath,
      fileType: fileType ?? this.fileType,
    );
  }
}
