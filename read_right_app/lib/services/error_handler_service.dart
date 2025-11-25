// FILE: lib/services/error_handler_service.dart
// PURPOSE: Centralized error handling with user-friendly messages and retry logic
// TOOLS: Flutter core, permission_handler
// RELATIONSHIPS: Used throughout app for consistent error handling

import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class ErrorHandlerService {
  static const int maxRetries = 3;
  static const Duration initialRetryDelay = Duration(seconds: 2);

  /// Handle microphone permission with user-friendly dialogs
  static Future<bool> handleMicrophonePermission(BuildContext context) async {
    try {
      final status = await Permission.microphone.status;

      if (status.isGranted) {
        return true;
      }

      if (status.isDenied) {
        // First time asking - explain why we need it
        final shouldRequest = await _showPermissionDialog(
          context,
          title: 'Microphone Access Needed',
          message:
              'We need access to your microphone to help you practice pronunciation. Your recordings are only used for scoring and can be deleted anytime.',
          primaryButton: 'Allow Access',
          secondaryButton: 'Not Now',
        );

        if (shouldRequest) {
          final result = await Permission.microphone.request();
          return result.isGranted;
        }
        return false;
      }

      if (status.isPermanentlyDenied) {
        // User previously denied - guide them to settings
        final shouldOpenSettings = await _showPermissionDialog(
          context,
          title: 'Permission Required',
          message:
              'Microphone access was previously denied. To use pronunciation practice, please enable it in your device settings.',
          primaryButton: 'Open Settings',
          secondaryButton: 'Cancel',
        );

        if (shouldOpenSettings) {
          await openAppSettings();
        }
        return false;
      }

      return false;
    } catch (e) {
      debugPrint('ErrorHandler: Permission check failed: $e');
      _showErrorSnackBar(
        context,
        'Unable to check microphone permission. Please try again.',
      );
      return false;
    }
  }

  /// Show permission dialog
  static Future<bool> _showPermissionDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String primaryButton,
    required String secondaryButton,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(secondaryButton),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(primaryButton),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Retry logic with exponential backoff
  static Future<T?> retryWithBackoff<T>({
    required Future<T> Function() operation,
    required BuildContext context,
    String? operationName,
    int maxAttempts = maxRetries,
  }) async {
    int attempts = 0;
    Duration delay = initialRetryDelay;

    while (attempts < maxAttempts) {
      try {
        return await operation();
      } on SocketException catch (e) {
        attempts++;
        debugPrint(
            'ErrorHandler: Network error (attempt $attempts/$maxAttempts): $e');

        if (attempts >= maxAttempts) {
          _showErrorSnackBar(
            context,
            'No internet connection. Please check your network and try again.',
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => retryWithBackoff(
                operation: operation,
                context: context,
                operationName: operationName,
              ),
            ),
          );
          return null;
        }

        // Show retry message
        _showInfoSnackBar(
          context,
          'Connection lost. Retrying in ${delay.inSeconds}s... ($attempts/$maxAttempts)',
        );

        await Future.delayed(delay);
        delay *= 2; // Exponential backoff
      } on TimeoutException catch (e) {
        attempts++;
        debugPrint(
            'ErrorHandler: Timeout (attempt $attempts/$maxAttempts): $e');

        if (attempts >= maxAttempts) {
          _showErrorSnackBar(
            context,
            'Request timed out. Please try again later.',
          );
          return null;
        }

        await Future.delayed(delay);
        delay *= 2;
      } catch (e) {
        debugPrint('ErrorHandler: Unexpected error: $e');
        _showErrorSnackBar(
          context,
          operationName != null
              ? '$operationName failed. Please try again.'
              : 'Something went wrong. Please try again.',
        );
        return null;
      }
    }

    return null;
  }

  /// Handle network-specific errors
  static Future<T?> handleNetworkOperation<T>({
    required Future<T> Function() operation,
    required BuildContext context,
    String? successMessage,
    String? errorMessage,
  }) async {
    try {
      final result = await operation();
      
      if (successMessage != null) {
        _showSuccessSnackBar(context, successMessage);
      }
      
      return result;
    } on SocketException {
      _showErrorSnackBar(
        context,
        errorMessage ?? 'No internet connection. Changes saved locally.',
        backgroundColor: Colors.orange,
      );
      return null;
    } on TimeoutException {
      _showErrorSnackBar(
        context,
        'Connection timeout. Please try again.',
      );
      return null;
    } catch (e) {
      debugPrint('ErrorHandler: Network operation failed: $e');
      _showErrorSnackBar(
        context,
        errorMessage ?? 'Operation failed. Please try again.',
      );
      return null;
    }
  }

  /// Show error snackbar
  static void _showErrorSnackBar(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Color? backgroundColor,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor ?? Colors.red.shade700,
        action: action,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Show info snackbar
  static void _showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 2,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue.shade700,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Show success snackbar
  static void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Check internet connectivity
  static Future<bool> isConnected() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Show offline banner
  static void showOfflineBanner(BuildContext context) {
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        content: const Row(
          children: [
            Icon(Icons.cloud_off, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'You\'re offline. Changes will sync when reconnected.',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade700,
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
            },
            child: const Text(
              'DISMISS',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// Hide offline banner
  static void hideOfflineBanner(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
  }
}