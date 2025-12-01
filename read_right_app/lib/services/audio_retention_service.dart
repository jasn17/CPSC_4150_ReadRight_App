// FILE: lib/services/audio_retention_service.dart
// PURPOSE: Handle secure audio recording upload and retrieval for teacher playback
// TOOLS: Firebase Storage, SharedPreferences
// RELATIONSHIPS: Used by PracticeModel when audio retention is enabled

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class AudioRetentionService {
  static const String _retentionKey = 'audio_retention_enabled';
  static const int _retentionDays = 30; // COPPA/FERPA compliance
  
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Check if audio retention is enabled for this user
  Future<bool> isAudioRetentionEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_retentionKey) ?? false;
  }

  /// Enable/disable audio retention
  Future<void> setAudioRetention(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_retentionKey, enabled);
    debugPrint('AudioRetention: ${enabled ? 'Enabled' : 'Disabled'}');
  }

  /// Upload audio recording to Firebase Storage
  /// Returns the download URL or null if upload fails
  Future<String?> uploadAudioRecording({
    required String userId,
    required String attemptId,
    required List<int> audioBytes,
    required String wordList,
    required String targetWord,
  }) async {
    try {
      // Check if retention is enabled
      final enabled = await isAudioRetentionEnabled();
      if (!enabled) {
        debugPrint('AudioRetention: Upload skipped - retention disabled');
        return null;
      }

      // Create file path: /audio_recordings/{userId}/{attemptId}.wav
      final path = 'audio_recordings/$userId/$attemptId.wav';
      final ref = _storage.ref().child(path);

      // Set metadata
      final metadata = SettableMetadata(
        contentType: 'audio/wav',
        customMetadata: {
          'userId': userId,
          'attemptId': attemptId,
          'wordList': wordList,
          'targetWord': targetWord,
          'uploadTimestamp': DateTime.now().toIso8601String(),
          'expiresAt': DateTime.now()
              .add(Duration(days: _retentionDays))
              .toIso8601String(),
        },
      );

      // Upload bytes
      debugPrint('AudioRetention: Uploading ${audioBytes.length} bytes to $path');
      final uploadTask = ref.putData(Uint8List.fromList(audioBytes), metadata);
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      debugPrint('AudioRetention: Upload successful - $downloadUrl');
      return downloadUrl;
      
    } catch (e) {
      debugPrint('AudioRetention: Upload failed: $e');
      return null;
    }
  }

  /// Get download URL for a specific attempt's audio
  Future<String?> getAudioUrl({
    required String userId,
    required String attemptId,
  }) async {
    try {
      final path = 'audio_recordings/$userId/$attemptId.wav';
      final ref = _storage.ref().child(path);
      
      // Check if file exists and get URL
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      debugPrint('AudioRetention: Failed to get URL: $e');
      return null;
    }
  }

  /// Download audio file for playback
  Future<File?> downloadAudioForPlayback({
    required String userId,
    required String attemptId,
  }) async {
    try {
      final url = await getAudioUrl(userId: userId, attemptId: attemptId);
      if (url == null) return null;

      // Download to temp directory
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/playback_$attemptId.wav');
      
      final ref = _storage.ref().child('audio_recordings/$userId/$attemptId.wav');
      await ref.writeToFile(tempFile);
      
      debugPrint('AudioRetention: Downloaded to ${tempFile.path}');
      return tempFile;
    } catch (e) {
      debugPrint('AudioRetention: Download failed: $e');
      return null;
    }
  }

  /// Delete a specific audio recording
  Future<bool> deleteAudioRecording({
    required String userId,
    required String attemptId,
  }) async {
    try {
      final path = 'audio_recordings/$userId/$attemptId.wav';
      final ref = _storage.ref().child(path);
      
      await ref.delete();
      debugPrint('AudioRetention: Deleted $path');
      return true;
    } catch (e) {
      debugPrint('AudioRetention: Delete failed: $e');
      return false;
    }
  }

  /// Delete all audio recordings for a user
  Future<int> deleteAllUserRecordings(String userId) async {
    int deletedCount = 0;
    
    try {
      final listResult = await _storage.ref()
          .child('audio_recordings/$userId')
          .listAll();
      
      for (final item in listResult.items) {
        try {
          await item.delete();
          deletedCount++;
        } catch (e) {
          debugPrint('AudioRetention: Failed to delete ${item.name}: $e');
        }
      }
      
      debugPrint('AudioRetention: Deleted $deletedCount recordings for user $userId');
      return deletedCount;
    } catch (e) {
      debugPrint('AudioRetention: Failed to delete user recordings: $e');
      return deletedCount;
    }
  }

  /// Clean up expired recordings (older than retention period)
  Future<int> cleanupExpiredRecordings(String userId) async {
    int deletedCount = 0;
    final expirationDate = DateTime.now().subtract(Duration(days: _retentionDays));
    
    try {
      final listResult = await _storage.ref()
          .child('audio_recordings/$userId')
          .listAll();
      
      for (final item in listResult.items) {
        try {
          final metadata = await item.getMetadata();
          final uploadTimestamp = metadata.customMetadata?['uploadTimestamp'];
          
          if (uploadTimestamp != null) {
            final uploadDate = DateTime.parse(uploadTimestamp);
            
            if (uploadDate.isBefore(expirationDate)) {
              await item.delete();
              deletedCount++;
              debugPrint('AudioRetention: Deleted expired recording ${item.name}');
            }
          }
        } catch (e) {
          debugPrint('AudioRetention: Error processing ${item.name}: $e');
        }
      }
      
      debugPrint('AudioRetention: Cleaned up $deletedCount expired recordings');
      return deletedCount;
    } catch (e) {
      debugPrint('AudioRetention: Cleanup failed: $e');
      return deletedCount;
    }
  }

  /// Get list of all recordings for a user (teacher view)
  Future<List<Map<String, dynamic>>> getUserRecordings(String userId) async {
    final recordings = <Map<String, dynamic>>[];
    
    try {
      final listResult = await _storage.ref()
          .child('audio_recordings/$userId')
          .listAll();
      
      for (final item in listResult.items) {
        try {
          final metadata = await item.getMetadata();
          final url = await item.getDownloadURL();
          
          recordings.add({
            'attemptId': item.name.replaceAll('.wav', ''),
            'downloadUrl': url,
            'targetWord': metadata.customMetadata?['targetWord'] ?? 'Unknown',
            'wordList': metadata.customMetadata?['wordList'] ?? 'Unknown',
            'uploadTimestamp': metadata.customMetadata?['uploadTimestamp'],
            'size': metadata.size,
          });
        } catch (e) {
          debugPrint('AudioRetention: Error reading metadata for ${item.name}: $e');
        }
      }
      
      // Sort by timestamp (newest first)
      recordings.sort((a, b) {
        final aTime = a['uploadTimestamp'] as String?;
        final bTime = b['uploadTimestamp'] as String?;
        if (aTime == null || bTime == null) return 0;
        return DateTime.parse(bTime).compareTo(DateTime.parse(aTime));
      });
      
      return recordings;
    } catch (e) {
      debugPrint('AudioRetention: Failed to list recordings: $e');
      return recordings;
    }
  }
}