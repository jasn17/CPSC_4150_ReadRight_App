// FILE: lib/widgets/sync_status_widget.dart
// PURPOSE: Shows sync status and allows manual sync

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sync_service.dart';

class SyncStatusWidget extends StatelessWidget {
  const SyncStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final syncService = context.watch<SyncService>();

    // Don't show anything if everything is synced and online
    if (syncService.unsyncedCount == 0 && syncService.isOnline) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _getBackgroundColor(syncService),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getBorderColor(syncService)),
      ),
      child: Row(
        children: [
          _buildIcon(syncService),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getStatusText(syncService),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (syncService.unsyncedCount > 0)
                  Text(
                    '${syncService.unsyncedCount} ${syncService.unsyncedCount == 1 ? 'attempt' : 'attempts'} pending',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          if (syncService.isOnline && 
              syncService.unsyncedCount > 0 && 
              !syncService.isSyncing)
            TextButton(
              onPressed: () => syncService.forceSyncNow(),
              child: const Text('Sync Now'),
            ),
          if (syncService.isSyncing)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Color _getBackgroundColor(SyncService syncService) {
    if (!syncService.isOnline) {
      return Colors.orange.shade50;
    }
    if (syncService.isSyncing) {
      return Colors.blue.shade50;
    }
    if (syncService.unsyncedCount > 0) {
      return Colors.amber.shade50;
    }
    return Colors.green.shade50;
  }

  Color _getBorderColor(SyncService syncService) {
    if (!syncService.isOnline) {
      return Colors.orange.shade300;
    }
    if (syncService.isSyncing) {
      return Colors.blue.shade300;
    }
    if (syncService.unsyncedCount > 0) {
      return Colors.amber.shade300;
    }
    return Colors.green.shade300;
  }

  Widget _buildIcon(SyncService syncService) {
    if (!syncService.isOnline) {
      return const Icon(Icons.cloud_off, color: Colors.orange);
    }
    if (syncService.isSyncing) {
      return const Icon(Icons.cloud_sync, color: Colors.blue);
    }
    if (syncService.unsyncedCount > 0) {
      return const Icon(Icons.cloud_upload, color: Colors.amber);
    }
    return const Icon(Icons.cloud_done, color: Colors.green);
  }

  String _getStatusText(SyncService syncService) {
    if (!syncService.isOnline) {
      return 'Offline Mode';
    }
    if (syncService.isSyncing) {
      return 'Syncing...';
    }
    if (syncService.unsyncedCount > 0) {
      return 'Ready to Sync';
    }
    return 'All Synced';
  }
}