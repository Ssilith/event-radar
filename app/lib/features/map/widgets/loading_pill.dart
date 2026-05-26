import 'package:event_radar/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

class LoadingPill extends StatelessWidget {
  const LoadingPill({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child:
                CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Text(
            AppL10n.of(context).loadingEvents,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
