import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/pairing_model.dart';
import '../../domain/repositories/pairing_repository.dart';
import '../../core/constants/constants.dart';

class PairingRepositoryImpl implements PairingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  String generatePairId() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    // Generate a 16-character secure random ID
    return List.generate(16, (index) => chars[random.nextInt(chars.length)]).join();
  }

  @override
  Future<void> initiatePairing(String pairId, String desktopDeviceName, String? fcmToken) async {
    final pairing = PairingModel(
      pairId: pairId,
      desktopDeviceName: desktopDeviceName,
      status: 'pending',
      desktopFCMToken: fcmToken,
      cleanupHours: 24, // default auto delete after 24 hours
    );

    await _firestore
        .collection(AppConstants.pairingsCollection)
        .doc(pairId)
        .set(pairing.toMap());
  }

  @override
  Future<void> completePairing(String pairId, String androidDeviceName, String? fcmToken) async {
    await _firestore
        .collection(AppConstants.pairingsCollection)
        .doc(pairId)
        .update({
      'androidDeviceName': androidDeviceName,
      'status': 'paired',
      'androidFCMToken': fcmToken,
      'pairedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> disconnectPairing(String pairId) async {
    await _firestore
        .collection(AppConstants.pairingsCollection)
        .doc(pairId)
        .update({
      'status': 'disconnected',
    });
  }

  @override
  Future<void> updateCleanupConfig(String pairId, int? cleanupHours) async {
    await _firestore
        .collection(AppConstants.pairingsCollection)
        .doc(pairId)
        .update({
      'cleanupHours': cleanupHours,
    });
  }

  @override
  Stream<PairingModel?> watchPairingState(String pairId) {
    return _firestore
        .collection(AppConstants.pairingsCollection)
        .doc(pairId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return PairingModel.fromMap(snapshot.data()!);
    });
  }
}
