import 'package:cloud_firestore/cloud_firestore.dart';

class PairingModel {
  final String pairId;
  final String desktopDeviceName;
  final String? androidDeviceName;
  final String status; // 'pending', 'paired', 'disconnected'
  final DateTime? pairedAt;
  final String? desktopFCMToken;
  final String? androidFCMToken;
  final int? cleanupHours; // Configuration option for auto delete (24, 72, 168 or null)

  PairingModel({
    required this.pairId,
    required this.desktopDeviceName,
    this.androidDeviceName,
    required this.status,
    this.pairedAt,
    this.desktopFCMToken,
    this.androidFCMToken,
    this.cleanupHours,
  });

  Map<String, dynamic> toMap() {
    return {
      'pairId': pairId,
      'desktopDeviceName': desktopDeviceName,
      'androidDeviceName': androidDeviceName,
      'status': status,
      'pairedAt': pairedAt != null ? Timestamp.fromDate(pairedAt!) : null,
      'desktopFCMToken': desktopFCMToken,
      'androidFCMToken': androidFCMToken,
      'cleanupHours': cleanupHours,
    };
  }

  factory PairingModel.fromMap(Map<String, dynamic> map) {
    return PairingModel(
      pairId: map['pairId'] ?? '',
      desktopDeviceName: map['desktopDeviceName'] ?? '',
      androidDeviceName: map['androidDeviceName'],
      status: map['status'] ?? 'pending',
      pairedAt: map['pairedAt'] != null
          ? (map['pairedAt'] as Timestamp).toDate()
          : null,
      desktopFCMToken: map['desktopFCMToken'],
      androidFCMToken: map['androidFCMToken'],
      cleanupHours: map['cleanupHours'],
    );
  }

  PairingModel copyWith({
    String? pairId,
    String? desktopDeviceName,
    String? androidDeviceName,
    String? status,
    DateTime? pairedAt,
    String? desktopFCMToken,
    String? androidFCMToken,
    int? cleanupHours,
  }) {
    return PairingModel(
      pairId: pairId ?? this.pairId,
      desktopDeviceName: desktopDeviceName ?? this.desktopDeviceName,
      androidDeviceName: androidDeviceName ?? this.androidDeviceName,
      status: status ?? this.status,
      pairedAt: pairedAt ?? this.pairedAt,
      desktopFCMToken: desktopFCMToken ?? this.desktopFCMToken,
      androidFCMToken: androidFCMToken ?? this.androidFCMToken,
      cleanupHours: cleanupHours ?? this.cleanupHours,
    );
  }
}
