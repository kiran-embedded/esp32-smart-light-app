import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/switch_device.dart';

class GoogleHomeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sync device to Firestore (for Google Home integration)
  Future<void> syncDeviceToCloud(SwitchDevice device) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('devices')
          .doc(device.id)
          .set(device.toJson(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to sync device to cloud: $e');
    }
  }

  // Sync all devices
  Future<void> syncAllDevices(List<SwitchDevice> devices) async {
    for (final device in devices) {
      await syncDeviceToCloud(device);
    }
  }

  // Listen to device changes from cloud (Google Home updates)
  Stream<List<SwitchDevice>> listenToDevices() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('devices')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => SwitchDevice.fromJson(doc.data()))
              .toList();
        });
  }

  // Update device state (called by Google Home)
  Future<void> updateDeviceState(String deviceId, bool isActive) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('devices')
          .doc(deviceId)
          .update({'isActive': isActive});
    } catch (e) {
      throw Exception('Failed to update device state: $e');
    }
  }

  // Unlink Google Home (clear cloud data)
  Future<void> unlinkGoogleHome() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Option 1: Clear all device data
      final devicesSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('devices')
          .get();

      final batch = _firestore.batch();
      for (final doc in devicesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Option 2: Just mark as unlinked (preserve data)
      await _firestore.collection('users').doc(user.uid).update({
        'googleHomeLinked': false,
      });
    } catch (e) {
      throw Exception('Failed to unlink Google Home: $e');
    }
  }

  // Check if Google Home is linked (Stream version for reactivity)
  Stream<bool> linkStatusStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(false);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((doc) => doc.data()?['googleHomeLinked'] ?? false);
  }

  // Check if Google Home is linked
  Future<bool> isGoogleHomeLinked() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.data()?['googleHomeLinked'] ?? false;
    } catch (e) {
      return false;
    }
  }

  // Link Google Home
  Future<void> linkGoogleHome() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'googleHomeLinked': true,
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to link Google Home: $e');
    }
  }
}
