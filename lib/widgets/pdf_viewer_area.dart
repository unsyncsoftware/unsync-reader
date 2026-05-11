import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
import '../providers/pdf_provider.dart';

class PdfViewerArea extends ConsumerWidget {
  const PdfViewerArea({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final document = ref.watch(currentDocumentProvider);
    final invert = ref.watch(pageInvertProvider);
    final controller = ref.watch(pdfViewerControllerProvider);

    // ─── SYNC PAGE NAVIGATION TO CONTROLLER ──────────────────────────
    ref.listen(currentPageProvider, (previous, next) {
      if (controller.isReady && previous != next) {
        controller.goToPage(pageNumber: next);
      }
    });

    if (document == null) return const SizedBox.shrink();

    return ColorFiltered(
      colorFilter: invert
          ? const ColorFilter.matrix(<double>[
              -1, 0, 0, 0, 255,
              0, -1, 0, 0, 255,
              0, 0, -1, 0, 255,
              0, 0, 0, 1, 0,
            ])
          : const ColorFilter.mode(
              Colors.transparent,
              BlendMode.dst,
            ),
      child: PdfViewer.file(
        document.path,
        controller: controller,
        params: PdfViewerParams(
          maxScale: 8.0,
          minScale: 0.5,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          // ─── SYNC CONTROLLER PAGE TO PROVIDER ────────────────────
          onPageChanged: (page) {
            if (page != null) {
              ref.read(currentPageProvider.notifier).state = page;
            }
          },
        ),
      ),
    );
  }
}