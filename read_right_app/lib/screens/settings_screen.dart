// FILE: lib/screens/settings_screen.dart
// PURPOSE: Configure assessment provider, threshold, audio retention; demo role toggle and sign-out.
// TOOLS: Flutter core; provider (watch/write SettingsModel and AuthModel).
// RELATIONSHIPS: Writes SettingsModel fields; toggles AuthModel.role; calls AuthModel.signOut().

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/settings_model.dart';
import '../models/auth_model.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const ListTile(title: Text('Assessment Provider')),
          RadioListTile<String>(
            title: const Text('Local (mock)'),
            value: 'local',
            groupValue: s.assessor,
            onChanged: (v) => context.read<SettingsModel>().assessor = v!,
          ),
          RadioListTile<String>(
            title: const Text('Cloud (placeholder)'),
            value: 'cloud',
            groupValue: s.assessor,
            onChanged: (v) => context.read<SettingsModel>().assessor = v!,
          ),
          const Divider(),
          ListTile(
            title: const Text('Pass Threshold'),
            subtitle: Text('${s.threshold}'),
            trailing: SizedBox(
              width: 160,
              child: Slider(
                value: s.threshold.toDouble(),
                min: 50,
                max: 100,
                divisions: 10,
                label: '${s.threshold}',
                onChanged: (v) => context.read<SettingsModel>().threshold = v.round(),
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Retain Audio (placeholder)'),
            value: s.retainAudio,
            onChanged: (v) => context.read<SettingsModel>().retainAudio = v,
          ),
          const Divider(),
          ListTile(
            title: const Text('Sign Out'),
            trailing: const Icon(Icons.logout),
            onTap: () => context.read<AuthModel>().signOut(),
          ),
        ],
      ),
    );
  }
}
