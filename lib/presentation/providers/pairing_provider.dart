import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../domain/models/pairing_model.dart';
import '../../domain/repositories/pairing_repository.dart';
import '../../data/repositories/pairing_repository_impl.dart';
import '../../data/repositories/mock_pairing_repository.dart';
import 'settings_provider.dart';

final demoModeProvider = StateProvider<bool>((ref) => false);

final pairingRepositoryProvider = Provider<PairingRepository>((ref) {
  final demoMode = ref.watch(demoModeProvider);
  if (Firebase.apps.isEmpty || demoMode) {
    return MockPairingRepository();
  }
  return PairingRepositoryImpl();
});

class PairingState {
  final PairingModel? pairing;
  final String localDeviceName;
  final String? activePairId;
  final bool isLoading;
  final String? errorMessage;

  PairingState({
    this.pairing,
    required this.localDeviceName,
    this.activePairId,
    this.isLoading = false,
    this.errorMessage,
  });

  PairingState copyWith({
    PairingModel? pairing,
    String? localDeviceName,
    String? activePairId,
    bool? isLoading,
    String? errorMessage,
    bool clearPairing = false,
  }) {
    return PairingState(
      pairing: clearPairing ? null : (pairing ?? this.pairing),
      localDeviceName: localDeviceName ?? this.localDeviceName,
      activePairId: clearPairing ? null : (activePairId ?? this.activePairId),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class PairingNotifier extends StateNotifier<PairingState> {
  final PairingRepository _repository;
  StreamSubscription<PairingModel?>? _stateSubscription;
  final Ref _ref;

  PairingNotifier(this._ref)
      : _repository = _ref.read(pairingRepositoryProvider),
        super(PairingState(localDeviceName: 'Unknown Device')) {
    _initDeviceName();
  }

  Future<void> _initDeviceName() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String name = 'Unknown Device';
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        name = '${androidInfo.brand} ${androidInfo.model}';
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        name = windowsInfo.computerName;
      }
    } catch (e) {
      name = Platform.isAndroid ? 'Android Device' : 'Windows PC';
    }
    state = state.copyWith(localDeviceName: name);
  }

  /// Initiates pairing by generating a secure Pair ID (Desktop side)
  Future<String> startDesktopPairing() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final String pairId = _repository.generatePairId();
      await _repository.initiatePairing(pairId, state.localDeviceName, null);
      
      state = state.copyWith(
        activePairId: pairId,
        isLoading: false,
      );
      
      _listenToPairingUpdates(pairId);
      return pairId;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  /// Scans QR and connects (Android side)
  Future<void> connectToDevice(String pairId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.completePairing(pairId, state.localDeviceName, null);
      
      state = state.copyWith(
        activePairId: pairId,
        isLoading: false,
      );
      
      _listenToPairingUpdates(pairId);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  /// Disconnects the session
  Future<void> disconnect() async {
    final String? pairId = state.activePairId;
    if (pairId == null) return;
    
    state = state.copyWith(isLoading: true);
    try {
      await _repository.disconnectPairing(pairId);
      await _stateSubscription?.cancel();
      state = state.copyWith(clearPairing: true, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Updates the auto-delete config in Firestore
  Future<void> changeCleanupConfig(int? hours) async {
    final String? pairId = state.activePairId;
    if (pairId == null) return;
    try {
      await _repository.updateCleanupConfig(pairId, hours);
      _ref.read(settingsProvider.notifier).updateCleanupHours(hours);
    } catch (e) {
      debugPrint('Failed to update cleanup config in Firestore: $e');
    }
  }

  void _listenToPairingUpdates(String pairId) {
    _stateSubscription?.cancel();
    _stateSubscription = _repository.watchPairingState(pairId).listen(
      (pairingModel) {
        if (pairingModel == null || pairingModel.status == 'disconnected') {
          // Reset local state if disconnected from the other side
          _stateSubscription?.cancel();
          state = state.copyWith(clearPairing: true);
        } else {
          state = state.copyWith(pairing: pairingModel);
          // Sync cleanup hours from Firestore config
          _ref.read(settingsProvider.notifier).updateCleanupHours(pairingModel.cleanupHours);
        }
      },
      onError: (err) {
        state = state.copyWith(errorMessage: err.toString());
      },
    );
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    super.dispose();
  }
}

final pairingProvider = StateNotifierProvider<PairingNotifier, PairingState>((ref) {
  return PairingNotifier(ref);
});
