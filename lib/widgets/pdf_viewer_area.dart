import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
import '../models/annotation.dart';
import '../providers/pdf_provider.dart';

// ─── PAGE RECT CACHE FOR ANNOTATION COORDINATE CONVERSION ────────────────
// Populated by pagePaintCallbacks on each render.
// Used in Phase 2 for accurate tap-to-PDF coordinate mapping.
final _pageRects = <int, Rect>{};
final _pageSize = <int, Size>{};

class PdfViewerArea extends ConsumerWidget {
  const PdfViewerArea({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final document = ref.watch(currentDocumentProvider);
    final invert = ref.watch(pageInvertProvider);
    final controller = ref.watch(pdfViewerControllerProvider);
    final annotations = ref.watch(annotationsProvider);

    // ─── SYNC PAGE NAVIGATION TO CONTROLLER ──────────────────────────
    ref.listen(currentPageProvider, (previous, next) {
      if (controller.isReady && previous != next) {
        controller.goToPage(pageNumber: next);
      }
    });

    // ─── FORCE REPAINT WHEN ANNOTATIONS CHANGE ───────────────────────
    ref.listen(annotationsProvider, (previous, next) {
      if (controller.isReady) {
        controller.invalidate();
      }
    });

    if (document == null) return const SizedBox.shrink();

    return ColorFiltered(
      // ─── PAGE INVERSION FOR DARK READING MODE ──────────────────────
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
          // ─── SYNC CONTROLLER PAGE NUMBER TO PROVIDER ───────────────
          onPageChanged: (page) {
            if (page != null) {
              ref.read(currentPageProvider.notifier).state = page;
            }
          },
          // ─── DRAW ANNOTATIONS + CACHE PAGE RECTS ───────────────────
          // Page rects are stored for Phase 2 coordinate mapping.
          pagePaintCallbacks: [
            (canvas, pageRect, page) {
              _pageRects[page.pageNumber] = pageRect;
              _pageSize[page.pageNumber] = Size(page.width, page.height);
              _drawAnnotations(canvas, pageRect, page, annotations);
            },
          ],
        ),
      ),
    );

    // ─── PHASE 2: ANNOTATION TAP LAYER ───────────────────────────────
    // Accurate tap-to-PDF coordinate mapping is pending.
    // The architecture is in place — _handleTap and _pageRects are ready.
    // Blocked by coordinate system alignment between pdfrx viewport
    // and Syncfusion PDF coordinate space.
  }

  // ─── DRAW ANNOTATIONS ON PAGE CANVAS ─────────────────────────────────
  // Called on every page render. Converts PDF-space bounds to screen-space
  // and draws each annotation type on the canvas.
  void _drawAnnotations(
    Canvas canvas,
    Rect pageRect,
    PdfPage page,
    List<Annotation> annotations,
  ) {
    final pageAnnotations =
        annotations.where((a) => a.pageNumber == page.pageNumber).toList();

    for (final ann in pageAnnotations) {
      final scaleX = pageRect.width / page.width;
      final scaleY = pageRect.height / page.height;

      // ─── CONVERT PDF COORDS TO SCREEN COORDS ─────────────────────
      final screenRect = Rect.fromLTWH(
        pageRect.left + ann.bounds.left * scaleX,
        pageRect.top + ann.bounds.top * scaleY,
        ann.bounds.width * scaleX,
        ann.bounds.height * scaleY,
      );

      switch (ann.type) {
        case AnnotationType.highlight:
          canvas.drawRect(
            screenRect,
            Paint()
              ..color = ann.color.withOpacity(0.35)
              ..style = PaintingStyle.fill,
          );
          break;

        case AnnotationType.rectangle:
          canvas.drawRect(
            screenRect,
            Paint()
              ..color = ann.color
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.0,
          );
          break;

        case AnnotationType.text:
          if (ann.text != null) {
            final tp = TextPainter(
              text: TextSpan(
                text: ann.text,
                style: TextStyle(
                  color: ann.color,
                  fontSize: 14 * scaleX,
                  fontWeight: FontWeight.w500,
                ),
              ),
              textDirection: TextDirection.ltr,
            )..layout();
            tp.paint(canvas, screenRect.topLeft);
          }
          break;

        case AnnotationType.stickyNote:
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                screenRect.left,
                screenRect.top,
                24 * scaleX,
                24 * scaleY,
              ),
              const Radius.circular(4),
            ),
            Paint()
              ..color = ann.color
              ..style = PaintingStyle.fill,
          );
          break;
      }
    }
  }

  // ─── PHASE 2: TAP HANDLER ─────────────────────────────────────────────
  // Converts screen tap coordinates to PDF page coordinates.
  // Pending accurate coordinate alignment fix.
  void _handleTap(
    WidgetRef ref,
    BuildContext context,
    Tool tool,
    Offset screenOffset,
  ) {
    int tappedPage = ref.read(currentPageProvider);
    Offset pageOffset = screenOffset;

    for (final entry in _pageRects.entries) {
      if (entry.value.contains(pageOffset)) {
        tappedPage = entry.key;
        final pageRect = entry.value;
        final pageSize = _pageSize[entry.key]!;

        final scaleX = pageSize.width / pageRect.width;
        final scaleY = pageSize.height / pageRect.height;

        pageOffset = Offset(
          (screenOffset.dx - pageRect.left) * scaleX,
          (pageRect.bottom - screenOffset.dy) * scaleY,
        );
        break;
      }
    }

    switch (tool) {
      case Tool.highlight:
        _addAnnotation(ref, Annotation(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: AnnotationType.highlight,
          pageNumber: tappedPage,
          bounds: Rect.fromLTWH(pageOffset.dx - 50, pageOffset.dy - 10, 100, 20),
          color: Colors.yellow,
        ));
        break;

      case Tool.shape:
        _addAnnotation(ref, Annotation(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: AnnotationType.rectangle,
          pageNumber: tappedPage,
          bounds: Rect.fromLTWH(pageOffset.dx - 40, pageOffset.dy - 30, 80, 60),
          color: Colors.red,
        ));
        break;

      case Tool.stickyNote:
        _addAnnotation(ref, Annotation(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: AnnotationType.stickyNote,
          pageNumber: tappedPage,
          bounds: Rect.fromLTWH(pageOffset.dx, pageOffset.dy, 24, 24),
          color: Colors.amber,
        ));
        break;

      case Tool.typewriter:
        _showTextDialog(ref, context, tappedPage, pageOffset);
        break;

      case Tool.none:
        break;
    }
  }

  void _addAnnotation(WidgetRef ref, Annotation annotation) {
    final current = ref.read(annotationsProvider);
    ref.read(annotationsProvider.notifier).state = [...current, annotation];
  }

  // ─── TEXT INPUT DIALOG ────────────────────────────────────────────────
  void _showTextDialog(
    WidgetRef ref,
    BuildContext context,
    int pageNumber,
    Offset offset,
  ) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'Add Text',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Type your text...',
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF6C63FF)),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF6C63FF)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                _addAnnotation(ref, Annotation(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  type: AnnotationType.text,
                  pageNumber: pageNumber,
                  bounds: Rect.fromLTWH(offset.dx, offset.dy, 200, 30),
                  text: textController.text,
                  color: const Color(0xFF6C63FF),
                ));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add',
                style: TextStyle(color: Color(0xFF6C63FF))),
          ),
        ],
      ),
    );
  }
}