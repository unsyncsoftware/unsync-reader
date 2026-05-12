import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
import '../models/annotation.dart';
import '../providers/pdf_provider.dart';

// ─── STORE PAGE RECTS FOR COORDINATE CONVERSION ──────────────────────────
final _pageRects = <int, Rect>{};
final _pageSize = <int, Size>{};

class PdfViewerArea extends ConsumerWidget {
  const PdfViewerArea({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final document = ref.watch(currentDocumentProvider);
    final invert = ref.watch(pageInvertProvider);
    final controller = ref.watch(pdfViewerControllerProvider);
    final activeTool = ref.watch(activeToolProvider);
    final annotations = ref.watch(annotationsProvider);

    // ─── SYNC PAGE NAVIGATION TO CONTROLLER ──────────────────────────
    ref.listen(currentPageProvider, (previous, next) {
      if (controller.isReady && previous != next) {
        controller.goToPage(pageNumber: next);
      }
    });

    if (document == null) return const SizedBox.shrink();

    return Stack(
      children: [
        // ─── PDF VIEWER WITH COLOR INVERSION ───────────────────────
        ColorFiltered(
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
              onPageChanged: (page) {
                if (page != null) {
                  ref.read(currentPageProvider.notifier).state = page;
                }
              },
              // ─── DRAW ANNOTATIONS + CAPTURE PAGE RECTS ─────────
              pagePaintCallbacks: [
                (canvas, pageRect, page) {
                  _pageRects[page.pageNumber] = pageRect;
                  _pageSize[page.pageNumber] =
                      Size(page.width, page.height);
                  _drawAnnotations(canvas, pageRect, page, annotations);
                },
              ],
            ),
          ),
        ),

        // ─── ANNOTATION TAP LAYER ───────────────────────────────────
        if (activeTool != Tool.none)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapUp: (details) {
                print('TAP DETECTED: ${details.localPosition}');
                _handleTap(
                  ref,
                  context,
                  activeTool,
                  details.localPosition,
                );
              },
            ),
          ),
      ],
    );
  }

  // ─── DRAW ANNOTATIONS ON CANVAS ────────────────────────────────────
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

      final screenRect = Rect.fromLTWH(
        pageRect.left + ann.bounds.left * scaleX,
        pageRect.top + ann.bounds.top * scaleY,
        ann.bounds.width * scaleX,
        ann.bounds.height * scaleY,
      );

      switch (ann.type) {
        // ─── HIGHLIGHT ──────────────────────────────────────────
        case AnnotationType.highlight:
          canvas.drawRect(
            screenRect,
            Paint()
              ..color = ann.color.withOpacity(0.35)
              ..style = PaintingStyle.fill,
          );
          break;

        // ─── RECTANGLE ─────────────────────────────────────────
        case AnnotationType.rectangle:
          canvas.drawRect(
            screenRect,
            Paint()
              ..color = ann.color
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.0,
          );
          break;

        // ─── TEXT OVERLAY ───────────────────────────────────────
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

        // ─── STICKY NOTE ────────────────────────────────────────
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

  // ─── HANDLE TAP TO PLACE ANNOTATION ──────────────────────────────
  void _handleTap(
    WidgetRef ref,
    BuildContext context,
    Tool tool,
    Offset screenOffset,
  ) {
    // ─── FIND THE PAGE THAT CONTAINS THE TAP POINT ──────────────
    int tappedPage = ref.read(currentPageProvider);
    // ─── SUBTRACT SIDEBAR WIDTH FROM X COORDINATE ──────────────────
    const sidebarWidth = 220.0;
    Offset pageOffset = Offset(screenOffset.dx - sidebarWidth, screenOffset.dy);

    for (final entry in _pageRects.entries) {
      if (entry.value.contains(pageOffset)) {
        tappedPage = entry.key;
        final pageRect = entry.value;
        final pageSize = _pageSize[entry.key]!;

        final scaleX = pageSize.width / pageRect.width;
        final scaleY = pageSize.height / pageRect.height;

        pageOffset = Offset(
          (screenOffset.dx - pageRect.left) * scaleX,
          (screenOffset.dy - pageRect.top) * scaleY,
        );
        break;
      }
    }

    switch (tool) {
      // ─── PLACE HIGHLIGHT ───────────────────────────────────────
      case Tool.highlight:
        _addAnnotation(
          ref,
          Annotation(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            type: AnnotationType.highlight,
            pageNumber: tappedPage,
            bounds: Rect.fromLTWH(
                pageOffset.dx - 50, pageOffset.dy - 10, 100, 20),
            color: Colors.yellow,
          ),
        );
        break;

      // ─── PLACE RECTANGLE ───────────────────────────────────────
      case Tool.shape:
        _addAnnotation(
          ref,
          Annotation(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            type: AnnotationType.rectangle,
            pageNumber: tappedPage,
            bounds: Rect.fromLTWH(
                pageOffset.dx - 40, pageOffset.dy - 30, 80, 60),
            color: Colors.red,
          ),
        );
        break;

      // ─── PLACE STICKY NOTE ─────────────────────────────────────
      case Tool.stickyNote:
        _addAnnotation(
          ref,
          Annotation(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            type: AnnotationType.stickyNote,
            pageNumber: tappedPage,
            bounds: Rect.fromLTWH(pageOffset.dx, pageOffset.dy, 24, 24),
            color: Colors.amber,
          ),
        );
        break;

      // ─── PLACE TEXT OVERLAY ────────────────────────────────────
      case Tool.typewriter:
        _showTextDialog(ref, context, tappedPage, pageOffset);
        break;

      case Tool.none:
        break;
    }
  }

  // ─── ADD ANNOTATION TO STATE ──────────────────────────────────────
  void _addAnnotation(WidgetRef ref, Annotation annotation) {
    final current = ref.read(annotationsProvider);
    ref.read(annotationsProvider.notifier).state = [...current, annotation];
  }

  // ─── TEXT INPUT DIALOG ────────────────────────────────────────────
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
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                _addAnnotation(
                  ref,
                  Annotation(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    type: AnnotationType.text,
                    pageNumber: pageNumber,
                    bounds: Rect.fromLTWH(offset.dx, offset.dy, 200, 30),
                    text: textController.text,
                    color: const Color(0xFF6C63FF),
                  ),
                );
              }
              Navigator.pop(ctx);
            },
            child: const Text(
              'Add',
              style: TextStyle(color: Color(0xFF6C63FF)),
            ),
          ),
        ],
      ),
    );
  }
}