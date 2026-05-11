import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/pdf_provider.dart';
import '../widgets/sidebar.dart';
import '../widgets/toolbar.dart';
import '../widgets/pdf_viewer_area.dart';
import '../widgets/drop_zone.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final document = ref.watch(currentDocumentProvider);
    final sidebarVisible = ref.watch(sidebarVisibleProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // UnSync logo mark
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(
                child: Text(
                  'U',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text('Unsync Reader'),
            if (document != null) ...[
              const SizedBox(width: 8),
              const Text('·',
                  style: TextStyle(color: Colors.grey, fontSize: 18)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  document.fileName,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontWeight: FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        actions: [
           // Close document button
           if (document != null)
             IconButton(
               icon: const Icon(Icons.close),
               tooltip: 'Close document',
               onPressed: () {
                 ref.read(currentDocumentProvider.notifier).state = null;
                 ref.read(currentPageProvider.notifier).state = 1;
               },
          ),
          // Toggle sidebar
          IconButton(
            icon: const Icon(Icons.view_sidebar_outlined),
            tooltip: 'Toggle sidebar',
            onPressed: () => ref
                .read(sidebarVisibleProvider.notifier)
                .state = !sidebarVisible,
          ),
          // Page invert toggle
          IconButton(
            icon: const Icon(Icons.invert_colors_outlined),
            tooltip: 'Invert page colors',
            onPressed: () {
              final invert = ref.read(pageInvertProvider);
              ref.read(pageInvertProvider.notifier).state = !invert;
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // Sidebar
          if (sidebarVisible)
            const SizedBox(
              width: 220,
              child: Sidebar(),
            ),

          // Divider
          if (sidebarVisible)
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: Theme.of(context).dividerTheme.color,
            ),

          // Main area
          Expanded(
            child: Column(
              children: [
                // Toolbar - only show when document is open
                if (document != null) const Toolbar(),

                // PDF viewer or drop zone
                Expanded(
                  child: document != null
                      ? const PdfViewerArea()
                      : const DropZone(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
