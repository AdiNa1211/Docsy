import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class AppSidebar extends StatelessWidget {
  const AppSidebar({
    required this.recent,
    required this.currentPath,
    required this.batchActive,
    required this.onOpen,
    required this.onOpenRecent,
    required this.onShowFiles,
    required this.onShowBatch,
    super.key,
  });

  final List<String> recent;
  final String? currentPath;
  final bool batchActive;
  final VoidCallback onOpen;
  final ValueChanged<String> onOpenRecent;
  final VoidCallback onShowFiles;
  final VoidCallback onShowBatch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.colorScheme.surfaceContainerLow,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          FilledButton.tonalIcon(
            icon: const Icon(Icons.folder_open),
            label: const Text('Open file…'),
            onPressed: onOpen,
          ),
          const SizedBox(height: 16),
          Text('Tools', style: theme.textTheme.labelLarge),
          ListTile(
            dense: true,
            leading: const Icon(Icons.edit_document),
            title: const Text('Editor'),
            selected: !batchActive,
            onTap: onShowFiles,
          ),
          ListTile(
            dense: true,
            leading: const Icon(Icons.collections_outlined),
            title: const Text('Batch resize'),
            selected: batchActive,
            onTap: onShowBatch,
          ),
          const SizedBox(height: 16),
          Text('Recent', style: theme.textTheme.labelLarge),
          if (recent.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No recent files yet.',
                style: theme.textTheme.bodySmall,
              ),
            ),
          for (final path in recent)
            ListTile(
              dense: true,
              selected: path == currentPath,
              leading: const Icon(Icons.description_outlined, size: 20),
              title: Text(p.basename(path), overflow: TextOverflow.ellipsis),
              subtitle: Text(
                p.dirname(path),
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
              onTap: () => onOpenRecent(path),
            ),
        ],
      ),
    );
  }
}
