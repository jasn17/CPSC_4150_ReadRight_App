// FILE: lib/services/sync_service.dart
// PURPOSE: Handles syncing offline practice attempts to Firebase

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../models/practice_attempt.dart';
import 'local_db_service.dart';

class SyncService extends ChangeNotifier {
  final LocalDbService _localDb = LocalDbService.instance;
  final DatabaseReference _firebaseRef = FirebaseDatabase.instance.ref();
  
  bool _isSyncing = false;
  bool _isOnline = true;
  int _unsyncedCount = 0;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool get isSyncing => _isSyncing;
  bool get isOnline => _isOnline;
  int get unsyncedCount => _unsyncedCount;

  SyncService() {
    _init();
  }

  Future<void> _init() async {
    // Check initial connectivity
    await _checkConnectivity();
    
    // Update unsynced count
    await _updateUnsyncedCount();
    
    // Listen to connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) async {
        await _checkConnectivity();
        
        // Auto-sync when coming back online
        if (_isOnline && _unsyncedCount > 0) {
          await syncAttempts();
        }
      },
    );
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    final wasOffline = !_isOnline;
    
    _isOnline = connectivityResult.isNotEmpty && 
                !connectivityResult.contains(ConnectivityResult.none);
    
    if (wasOffline && _isOnline) {
      debugPrint('SyncService: Connection restored');
    } else if (!wasOffline && !_isOnline) {
      debugPrint('SyncService: Connection lost');
    }
    
    notifyListeners();
  }

  Future<void> _updateUnsyncedCount() async {
    _unsyncedCount = await _localDb.getUnsyncedCount();
    notifyListeners();
  }

  /// Save attempt locally and sync if online
  Future<void> saveAttempt(PracticeAttempt attempt) async {
    // Always save locally first
    await _localDb.saveAttempt(attempt);
    await _updateUnsyncedCount();
    
    // Try to sync immediately if online
    if (_isOnline) {
      await syncAttempts();
    }
  }

  /// Sync all unsynced attempts to Firebase
  Future<bool> syncAttempts() async {
    if (_isSyncing) {
      debugPrint('SyncService: Already syncing, skipping...');
      return false;
    }

    if (!_isOnline) {
      debugPrint('SyncService: Offline, cannot sync');
      return false;
    }

    _isSyncing = true;
    notifyListeners();

    try {
      final unsyncedAttempts = await _localDb.getUnsyncedAttempts();
      
      if (unsyncedAttempts.isEmpty) {
        debugPrint('SyncService: No attempts to sync');
        _isSyncing = false;
        notifyListeners();
        return true;
      }

      debugPrint('SyncService: Syncing ${unsyncedAttempts.length} attempts...');

      int syncedCount = 0;
      for (final attempt in unsyncedAttempts) {
        try {
          // Save to Firebase under: /practice_attempts/{userId}/{attemptId}
          await _firebaseRef
              .child('practice_attempts')
              .child(attempt.userId)
              .child(attempt.id)
              .set(attempt.toJson());

          // Mark as synced in local DB
          await _localDb.markAsSynced(attempt.id);
          syncedCount++;
          
        } catch (e) {
          debugPrint('SyncService: Failed to sync attempt ${attempt.id}: $e');
          // Continue with next attempt instead of failing completely
        }
      }

      debugPrint('SyncService: Successfully synced $syncedCount/${unsyncedAttempts.length} attempts');
      
      await _updateUnsyncedCount();
      
      // Cleanup old synced data
      await _localDb.cleanupOldAttempts();
      
      _isSyncing = false;
      notifyListeners();
      return syncedCount == unsyncedAttempts.length;
      
    } catch (e) {
      debugPrint('SyncService: Sync failed: $e');
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  /// Force a manual sync
  Future<void> forceSyncNow() async {
    await _checkConnectivity();
    if (_isOnline) {
      await syncAttempts();
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}