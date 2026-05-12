import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pdf_document.dart';
import '../providers/pdf_provider.dart';
import '../services/pdf_service.dart';

class Sidebar extends ConsumerWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final document = ref.watch(currentDocumentProvider);

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.folder_open_outlined, size: 16),
                label: const Text('Open PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => PdfService.openFile(ref, context),
              ),
            ),
          ),
          const Divider(height: 1),
          _SidebarSection(
            title: 'TOOLS',
            children: [
              _ToolItem(
                icon: Icons.call_merge_outlined,
                label: 'Merge PDFs',
                onTap: () => PdfService.mergePdfs(ref),
              ),
              _ToolItem(
                icon: Icons.call_split_outlined,
                label: 'Split PDF',
                onTap: document != null
                    ? () => PdfService.splitPdf(ref)
                    : null,
              ),
              _ToolItem(
                icon: Icons.image_outlined,
                label: 'Images → PDF',
                onTap: () => PdfService.imagesToPdf(ref),
              ),
              _ToolItem(
                icon: Icons.photo_library_outlined,
                label: 'PDF → Images',
                onTap: document != null
                    ? () => PdfService.pdfToImages(ref)
                    : null,
              ),
              _ToolItem(
                icon: Icons.rotate_right_outlined,
                label: 'Rotate Pages',
                onTap: document != null
                    ? () => PdfService.rotatePages(ref)
                    : null,
              ),
            ],
          ),
          const Divider(height: 1),
          _SidebarSection(
            title: 'RECENT',
            children: [
              Consumer(builder: (context, ref, _) {
                final recents = ref.watch(recentDocumentsProvider);
                if (recents.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Text(
                      'No recent files',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  );
                }
                return Column(
                  children: recents
                      .take(5)
                      .map((doc) => _ToolItem(
                            icon: Icons.picture_as_pdf_outlined,
                            label: doc.fileName,
                            onTap: () =>
                                PdfService.openFilePath(ref, doc.path),
                          ))
                      .toList(),
                );
              }),
            ],
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.lock_outline,
                    size: 12, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  'Local only · v1.0.0',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SidebarSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
        ...children,
      ],
    );
  }
}

class _ToolItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ToolItem({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(
        icon,
        size: 18,
        color: onTap != null
            ? Theme.of(context).colorScheme.onSurface
            : Colors.grey.withOpacity(0.4),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: onTap != null
              ? Theme.of(context).colorScheme.onSurface
              : Colors.grey.withOpacity(0.4),
        ),
        overflow: TextOverflow.ellipsis,
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
      horizontalTitleGap: 8,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
    );
  }
}