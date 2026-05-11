import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
import '../providers/pdf_provider.dart';

class PdfViewerArea extends ConsumerStatefulWidget {
  const PdfViewerArea({super.key});

  @override
  ConsumerState<PdfViewerArea> createState() => _PdfViewerAreaState();
}

class _PdfViewerAreaState extends ConsumerState<PdfViewerArea> {
  late final PdfViewerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PdfViewerController();
  }

  @override
  Widget build(BuildContext context) {
    final document = ref.watch(currentDocumentProvider);
    final invert = ref.watch(pageInvertProvider);

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
        controller: _controller,
        params: PdfViewerParams(
          maxScale: 8.0,
          minScale: 0.5,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          onPageChanged: (page) {
            ref.read(currentPageProvider.notifier).state = page ?? 1;
          },
        ),
      ),
    );
  }
}