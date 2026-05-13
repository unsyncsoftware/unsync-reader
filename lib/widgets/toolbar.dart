import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/pdf_provider.dart';
import '../services/pdf_service.dart';

class Toolbar extends ConsumerWidget {
  const Toolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPage = ref.watch(currentPageProvider);
    final document = ref.watch(currentDocumentProvider);

    return Container(
      height: 44,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // ─── ANNOTATION TOOLS (Phase 2) ───────────────────────────────
          _ToolButton(
            icon: Icons.highlight_outlined,
            tooltip: 'Highlight — Coming Soon',
            active: false,
            onTap: () {},
          ),
          _ToolButton(
            icon: Icons.sticky_note_2_outlined,
            tooltip: 'Sticky Note — Coming Soon',
            active: false,
            onTap: () {},
          ),
          _ToolButton(
            icon: Icons.title_outlined,
            tooltip: 'Add Text — Coming Soon',
            active: false,
            onTap: () {},
          ),
          _ToolButton(
            icon: Icons.crop_square_outlined,
            tooltip: 'Draw Shape — Coming Soon',
            active: false,
            onTap: () {},
          ),

          const VerticalDivider(width: 16, indent: 8, endIndent: 8),

          // ─── PAGE NAVIGATION ──────────────────────────────────────────
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

          // ─── ZOOM OUT ─────────────────────────────────────────────────
          IconButton(
            icon: const Icon(Icons.zoom_out),
            iconSize: 18,
            tooltip: 'Zoom out',
            onPressed: () {
              final controller = ref.read(pdfViewerControllerProvider);
              if (controller.isReady) {
                controller.setZoom(
                  controller.centerPosition,
                  controller.currentZoom - 0.25,
                );
              }
            },
          ),

          // ─── ZOOM PERCENTAGE ──────────────────────────────────────────
          Consumer(builder: (context, ref, _) {
            final controller = ref.watch(pdfViewerControllerProvider);
            return ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                final zoom =
                    controller.isReady ? controller.currentZoom : 1.0;
                return Text(
                  '${(zoom * 100).toStringAsFixed(0)}%',
                  style:
                      const TextStyle(fontSize: 12, color: Colors.grey),
                );
              },
            );
          }),

          // ─── ZOOM IN ──────────────────────────────────────────────────
          IconButton(
            icon: const Icon(Icons.zoom_in),
            iconSize: 18,
            tooltip: 'Zoom in',
            onPressed: () {
              final controller = ref.read(pdfViewerControllerProvider);
              if (controller.isReady) {
                controller.setZoom(
                  controller.centerPosition,
                  controller.currentZoom + 0.25,
                );
              }
            },
          ),

          const VerticalDivider(width: 16, indent: 8, endIndent: 8),

          // ─── SAVE ─────────────────────────────────────────────────────
          TextButton.icon(
            icon: const Icon(Icons.save_outlined, size: 16),
            label: const Text('Save'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
              textStyle: const TextStyle(fontSize: 13),
            ),
            onPressed: () => PdfService.saveWithAnnotations(ref, context),
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
                : Colors.grey.withOpacity(0.4),
          ),
        ),
      ),
    );
  }
}