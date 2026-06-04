import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../domain/models/pairing_model.dart';
import '../../domain/repositories/pairing_repository.dart';

class MockPairingRepository implements PairingRepository {
  static final _pairingController = BehaviorSubject<PairingModel?>(null);

  @override
  String generatePairId() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(16, (index) => chars[random.nextInt(chars.length)]).join();
  }

  @override
  Future<void> initiatePairing(String pairId, String desktopDeviceName, String? fcmToken) async {
    final pairing = PairingModel(
      pairId: pairId,
      desktopDeviceName: desktopDeviceName,
      status: 'pending',
      desktopFCMToken: fcmToken,
      cleanupHours: 24,
    );
    _pairingController.add(pairing);

    // Simulate auto-connection from a mock android device after 3.5 seconds
    Future.delayed(const Duration(milliseconds: 3500), () {
      final current = _pairingController.value;
      if (current != null && current.pairId == pairId && current.status == 'pending') {
        final paired = current.copyWith(
          status: 'paired',
          androidDeviceName: 'Mock Galaxy S24 Ultra',
          pairedAt: DateTime.now(),
        );
        _pairingController.add(paired);
        debugPrint('Mock Pairing handshake completed!');
      }
    });
  }

  @override
  Future<void> completePairing(String pairId, String androidDeviceName, String? fcmToken) async {
    final current = _pairingController.value;
    if (current != null && current.pairId == pairId) {
      final paired = current.copyWith(
        status: 'paired',
        androidDeviceName: androidDeviceName,
        androidFCMToken: fcmToken,
        pairedAt: DateTime.now(),
      );
      _pairingController.add(paired);
    } else {
      // Direct completion (Android side mock init)
      final paired = PairingModel(
        pairId: pairId,
        desktopDeviceName: 'Mock Windows PC',
        androidDeviceName: androidDeviceName,
        status: 'paired',
        androidFCMToken: fcmToken,
        pairedAt: DateTime.now(),
        cleanupHours: 24,
      );
      _pairingController.add(paired);
    }
  }

  @override
  Future<void> disconnectPairing(String pairId) async {
    final current = _pairingController.value;
    if (current != null && current.pairId == pairId) {
      _pairingController.add(current.copyWith(status: 'disconnected'));
    }
  }

  @override
  Future<void> updateCleanupConfig(String pairId, int? cleanupHours) async {
    final current = _pairingController.value;
    if (current != null && current.pairId == pairId) {
      _pairingController.add(current.copyWith(cleanupHours: cleanupHours));
    }
  }

  @override
  Stream<PairingModel?> watchPairingState(String pairId) {
    return _pairingController.stream.map((model) {
      if (model != null && model.pairId == pairId) {
        return model;
      }
      return null;
    });
  }
}

// Simple BehaviorSubject implementation for mock streams without external RxDart package
class BehaviorSubject<T> {
  T _value;
  final StreamController<T> _controller = StreamController<T>.broadcast();

  BehaviorSubject(this._value) {
    _controller.add(_value);
  }

  T get value => _value;

  Stream<T> get stream => _controller.stream;

  void add(T newValue) {
    _value = newValue;
    _controller.add(newValue);
  }

  void close() {
    _controller.close();
  }
}
