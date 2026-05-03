import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/update_service.dart';

class UpdateDialog extends StatelessWidget {
  final UpdateInfo info;
  const UpdateDialog({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.system_update_outlined, color: color, size: 20),
          const SizedBox(width: 8),
          const Text('Update Available'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${info.version} is ready to download.',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          if (info.releaseNotes != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                info.releaseNotes!.length > 240
                    ? '${info.releaseNotes!.substring(0, 237)}…'
                    : info.releaseNotes!,
                style:
                    const TextStyle(fontSize: 12, color: Colors.white54),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await UpdateService.skipVersion(info.version);
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Skip', style: TextStyle(color: Colors.white38)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Later'),
        ),
        FilledButton.icon(
          onPressed: () async {
            final uri = Uri.parse(info.releaseUrl);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
            if (context.mounted) Navigator.pop(context);
          },
          icon: const Icon(Icons.download_outlined, size: 16),
          label: const Text('Download'),
        ),
      ],
    );
  }
}
