import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
import '../models/pdf_document.dart';
import '../models/annotation.dart';


final currentDocumentProvider = StateProvider<PdfDoc?>((ref) => null);
final currentPageProvider = StateProvider<int>((ref) => 1);
final zoomLevelProvider = StateProvider<double>((ref) => 1.0);
final recentDocumentsProvider = StateProvider<List<PdfDoc>>((ref) => []);

enum Tool { none, highlight, stickyNote, shape, typewriter }

final activeToolProvider = StateProvider<Tool>((ref) => Tool.none);
final sidebarVisibleProvider = StateProvider<bool>((ref) => true);
final pageInvertProvider = StateProvider<bool>((ref) => false);



final pdfViewerControllerProvider = Provider<PdfViewerController>((ref) {
  return PdfViewerController();
});

// ─── ANNOTATIONS PROVIDER ─────────────────────────────────────────────────
final annotationsProvider =
    StateProvider<List<Annotation>>((ref) => []);