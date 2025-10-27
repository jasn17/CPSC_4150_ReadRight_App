// FILE: lib/widgets/primary_button.dart
// PURPOSE: Full-width primary button for consistent CTAs across screens.
// TOOLS: Flutter core.
// RELATIONSHIPS: Reused in login, practice, feedback, and future flows.

import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const PrimaryButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(onPressed: onPressed, child: Text(label)),
    );
  }
}
