import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/pdf_provider.dart';

class Toolbar extends ConsumerWidget {
  const Toolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTool = ref.watch(activeToolProvider);
    final currentPage = ref.watch(currentPageProvider);
    final document = ref.watch(currentDocumentProvider);

    return Container(
      height: 44,
      color: Theme.of(context).colorScheme.surfaceVariant,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // Annotation tools
          _ToolButton(
            icon: Icons.highlight_outlined,
            tooltip: 'Highlight',
            active: activeTool == Tool.highlight,
            onTap: () => ref.read(activeToolProvider.notifier).state =
                activeTool == Tool.highlight ? Tool.none : Tool.highlight,
          ),
          _ToolButton(
            icon: Icons.sticky_note_2_outlined,
            tooltip: 'Sticky Note',
            active: activeTool == Tool.stickyNote,
            onTap: () => ref.read(activeToolProvider.notifier).state =
                activeTool == Tool.stickyNote
                    ? Tool.none
                    : Tool.stickyNote,
          ),
          _ToolButton(
            icon: Icons.title_outlined,
            tooltip: 'Add Text',
            active: activeTool == Tool.typewriter,
            onTap: () => ref.read(activeToolProvider.notifier).state =
                activeTool == Tool.typewriter
                    ? Tool.none
                    : Tool.typewriter,
          ),
          _ToolButton(
            icon: Icons.crop_square_outlined,
            tooltip: 'Draw Shape',
            active: activeTool == Tool.shape,
            onTap: () => ref.read(activeToolProvider.notifier).state =
                activeTool == Tool.shape ? Tool.none : Tool.shape,
          ),

          const VerticalDivider(width: 16, indent: 8, endIndent: 8),

          // Page navigation
          IconButton(
            icon: const Icon(Icons.chevron_left),
            iconSize: 18,
            tooltip: 'Previous page',
            onPressed: currentPage > 1
                ? () => ref.read(currentPageProvider.notifier).state =
                    currentPage - 1
                : null,
          ),
          Text(
            '$currentPage / ${document?.pageCount ?? 1}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            iconSize: 18,
            tooltip: 'Next page',
            onPressed: document != null && currentPage < document.pageCount
                ? () => ref.read(currentPageProvider.notifier).state =
                    currentPage + 1
                : null,
          ),

          const Spacer(),

          // Zoom controls
          IconButton(
            icon: const Icon(Icons.zoom_out),
            iconSize: 18,
            tooltip: 'Zoom out',
            onPressed: () {
              final zoom = ref.read(zoomLevelProvider);
              if (zoom > 0.5) {
                ref.read(zoomLevelProvider.notifier).state =
                    (zoom - 0.1).clamp(0.5, 3.0);
              }
            },
          ),
          Consumer(builder: (context, ref, _) {
            final zoom = ref.watch(zoomLevelProvider);
            return Text(
              '${(zoom * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            );
          }),
          IconButton(
            icon: const Icon(Icons.zoom_in),
            iconSize: 18,
            tooltip: 'Zoom in',
            onPressed: () {
              final zoom = ref.read(zoomLevelProvider);
              if (zoom < 3.0) {
                ref.read(zoomLevelProvider.notifier).state =
                    (zoom + 0.1).clamp(0.5, 3.0);
              }
            },
          ),

          const VerticalDivider(width: 16, indent: 8, endIndent: 8),

          // Save button
          TextButton.icon(
            icon: const Icon(Icons.save_outlined, size: 16),
            label: const Text('Save'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
              textStyle: const TextStyle(fontSize: 13),
            ),
            onPressed: () {
              // TODO: implement save with flatten
            },
          ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool active;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.tooltip,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: active
                ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 18,
            color: active
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
          ),
        ),
      ),
    );
  }
}
