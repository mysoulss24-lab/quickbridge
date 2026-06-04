import '../models/pairing_model.dart';

abstract class PairingRepository {
  /// Generates a random difficult-to-guess Pair ID of at least 12 characters.
  String generatePairId();

  /// Starts a pairing session (created by Windows device).
  Future<void> initiatePairing(String pairId, String desktopDeviceName, String? fcmToken);

  /// Completes pairing session (scanned by Android device).
  Future<void> completePairing(String pairId, String androidDeviceName, String? fcmToken);

  /// Disconnects/unpairs the devices.
  Future<void> disconnectPairing(String pairId);

  /// Updates the auto-delete settings.
  Future<void> updateCleanupConfig(String pairId, int? cleanupHours);

  /// Stream of pairing state updates for a specific pairId.
  Stream<PairingModel?> watchPairingState(String pairId);
}
