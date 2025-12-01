// FILE: lib/widgets/audio_retention_settings.dart
// PURPOSE: Settings widget for audio retention privacy control
// TOOLS: Flutter core, AudioRetentionService
// RELATIONSHIPS: Used in settings screen

import 'package:flutter/material.dart';
import '../services/audio_retention_service.dart';

class AudioRetentionSettings extends StatefulWidget {
  const AudioRetentionSettings({super.key});

  @override
  State<AudioRetentionSettings> createState() => _AudioRetentionSettingsState();
}

class _AudioRetentionSettingsState extends State<AudioRetentionSettings> {
  final AudioRetentionService _audioService = AudioRetentionService();
  bool _isEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSetting();
  }

  Future<void> _loadSetting() async {
    final enabled = await _audioService.isAudioRetentionEnabled();
    setState(() {
      _isEnabled = enabled;
      _isLoading = false;
    });
  }

  Future<void> _toggleSetting(bool value) async {
    if (value) {
      // Enabling - show consent dialog
      final consent = await _showConsentDialog();
      if (!consent) return;
    } else {
      // Disabling - show confirmation
      final confirm = await _showDisableDialog();
      if (!confirm) return;
    }

    await _audioService.setAudioRetention(value);
    setState(() {
      _isEnabled = value;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Audio recordings enabled for teacher review'
                : 'Audio recordings disabled',
          ),
          backgroundColor: value ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  Future<bool> _showConsentDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.privacy_tip, color: Colors.blue),
                SizedBox(width: 8),
                Text('Audio Recording Privacy'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'When enabled, your pronunciation recordings will be:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _buildBulletPoint('Securely stored in the cloud'),
                  _buildBulletPoint('Available for teacher review'),
                  _buildBulletPoint('Automatically deleted after 30 days'),
                  _buildBulletPoint('Used only for educational purposes'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline,
                                size: 20, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Privacy Protection',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'You can disable this feature anytime. Teachers use recordings only to help improve pronunciation.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Do you consent to audio recording?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No, Don\'t Enable'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes, I Consent'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _showDisableDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Disable Audio Recording?'),
            content: const Text(
              'Your teacher will no longer be able to review your pronunciation recordings. Past recordings will remain for 30 days before automatic deletion.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
                child: const Text('Disable'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 18)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.mic,
                  color: _isEnabled ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Audio Recording for Teacher Review',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isEnabled
                            ? 'Teachers can review your recordings'
                            : 'Recordings are not saved',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isEnabled,
                  onChanged: _toggleSetting,
                  activeThumbColor: Colors.green,
                ),
              ],
            ),
            if (_isEnabled) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: Colors.green.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Recordings auto-delete after 30 days',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}