import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:syncfusion_flutter_pdf/pdf.dart' as sfpdf;
import '../models/pdf_document.dart';
import '../providers/pdf_provider.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:pdfrx/pdfrx.dart';
import 'storage_service.dart';
import '../models/annotation.dart';

class PdfService {

  static Future<void> openFile(WidgetRef ref, BuildContext context) async {
    // ─── CHECK FOR UNSAVED ANNOTATIONS ─────────────────────────────
    final annotations = ref.read(annotationsProvider);
    if (annotations.isNotEmpty) {
      final shouldDiscard = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF16213E),
          title: const Text(
            'Unsaved Annotations',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          content: const Text(
            'You have unsaved annotations on the current document. Opening a new file will discard them.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Save First',
                  style: TextStyle(color: Color(0xFF6C63FF))),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Discard & Open',
                  style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (shouldDiscard != true) return;

      // ─── CLEAR ANNOTATIONS IF USER CHOSE DISCARD ───────────────
      ref.read(annotationsProvider.notifier).state = [];
    }

    // ─── PICK AND OPEN NEW FILE ─────────────────────────────────────
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    await openFilePath(ref, result.files.first.path!);
  }

  static Future<void> openFilePath(WidgetRef ref, String path) async {
    final file = File(path);
    if (!file.existsSync()) return;

    final bytes = file.readAsBytesSync();
    final sfDoc = sfpdf.PdfDocument(inputBytes: bytes);
    final pageCount = sfDoc.pages.count;
    sfDoc.dispose();

    final doc = PdfDoc(
      path: path,
      name: p.basename(path),
      pageCount: pageCount,
      openedAt: DateTime.now(),
    );

    ref.read(currentDocumentProvider.notifier).state = doc;
    ref.read(currentPageProvider.notifier).state = 1;

    final recents = List<PdfDoc>.from(ref.read(recentDocumentsProvider));
    recents.removeWhere((d) => d.path == path);
    recents.insert(0, doc);
    final trimmed = recents.take(10).toList();
    ref.read(recentDocumentsProvider.notifier).state = trimmed;
    await StorageService.saveRecentFiles(trimmed.map((d) => d.path).toList());
  }

  static Future<void> mergePdfs(WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
    );
    if (result == null || result.files.length < 2) return;

    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save merged PDF',
      fileName: 'merged.pdf',
    );
    if (savePath == null) return;

    final output = sfpdf.PdfDocument();
    for (final file in result.files) {
      final src = sfpdf.PdfDocument(
          inputBytes: File(file.path!).readAsBytesSync());
      for (int i = 0; i < src.pages.count; i++) {
        final page = output.pages.add();
        final template = src.pages[i].createTemplate();
        page.graphics.drawPdfTemplate(
            template, const Offset(0, 0));
      }
      src.dispose();
    }

    final bytes = await output.save();
    await File(savePath).writeAsBytes(bytes);
    output.dispose();

    await openFilePath(ref, savePath);
  }

  static Future<void> splitPdf(WidgetRef ref) async {
    final document = ref.read(currentDocumentProvider);
    if (document == null) return;

    final outputDir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choose output folder',
    );
    if (outputDir == null) return;

    final bytes = File(document.path).readAsBytesSync();
    final src = sfpdf.PdfDocument(inputBytes: bytes);

    for (int i = 0; i < src.pages.count; i++) {
      final single = sfpdf.PdfDocument();
      final page = single.pages.add();
      final template = src.pages[i].createTemplate();
      page.graphics.drawPdfTemplate(
          template, const Offset(0, 0));

      final outPath = p.join(
        outputDir,
        '${p.basenameWithoutExtension(document.name)}_page_${i + 1}.pdf',
      );
      await File(outPath).writeAsBytes(await single.save());
      single.dispose();
    }
    src.dispose();
  }

  static Future<void> imagesToPdf(WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    if (result == null || result.files.isEmpty) return;

    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save PDF',
      fileName: 'images.pdf',
    );
    if (savePath == null) return;

    final doc = sfpdf.PdfDocument();
    for (final file in result.files) {
      final imageBytes = File(file.path!).readAsBytesSync();
      final image = sfpdf.PdfBitmap(imageBytes);
      final page = doc.pages.add();
      page.graphics.drawImage(
        image,
        Rect.fromLTWH(0, 0, page.size.width, page.size.height),
      );
    }

    await File(savePath).writeAsBytes(await doc.save());
    doc.dispose();
    await openFilePath(ref, savePath);
  }

  // ─── PDF TO IMAGES ────────────────────────────────────────────────────────
  static Future<void> pdfToImages(WidgetRef ref) async {
    final document = ref.read(currentDocumentProvider);
    if (document == null) return;

    // ─── PICK OUTPUT FOLDER ──────────────────────────────────────────
    final outputDir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choose output folder for images',
    );
    if (outputDir == null) return;

    final bytes = File(document.path).readAsBytesSync();
    final doc = sfpdf.PdfDocument(inputBytes: bytes);
    final pageCount = doc.pages.count;
    doc.dispose();

    // ─── OPEN PDF WITH PDFRX AND RENDER EACH PAGE ───────────────────
    final pdfDoc = await PdfDocument.openFile(document.path);

    for (int i = 0; i < pageCount; i++) {
      final page = await pdfDoc.pages[i].render(
        // ─── RENDER AT 150 DPI — GOOD QUALITY WITHOUT HUGE FILES ────
        fullWidth: pdfDoc.pages[i].width * 2,
        fullHeight: pdfDoc.pages[i].height * 2,
      );

      if (page == null) continue;

      final image = await page.createImage();
      final imageBytes = await image.toByteData(
          format: ui.ImageByteFormat.png);

      if (imageBytes == null) continue;

      final outputPath = p.join(
        outputDir,
        '${p.basenameWithoutExtension(document.name)}_page_${i + 1}.png',
      );

      await File(outputPath).writeAsBytes(imageBytes.buffer.asUint8List());
      page.dispose();
    }

    await pdfDoc.dispose();
  }
  

  // ─── ROTATE PAGES ─────────────────────────────────────────────────────────
  static Future<void> rotatePages(WidgetRef ref) async {
    final document = ref.read(currentDocumentProvider);
    if (document == null) return;

    final bytes = File(document.path).readAsBytesSync();
    final doc = sfpdf.PdfDocument(inputBytes: bytes);

    for (int i = 0; i < doc.pages.count; i++) {
      // ─── ROTATE EACH PAGE 90 DEGREES CLOCKWISE ──────────────────
      switch (doc.pages[i].rotation) {
        case sfpdf.PdfPageRotateAngle.rotateAngle0:
          doc.pages[i].rotation = sfpdf.PdfPageRotateAngle.rotateAngle90;
          break;
        case sfpdf.PdfPageRotateAngle.rotateAngle90:
          doc.pages[i].rotation = sfpdf.PdfPageRotateAngle.rotateAngle180;
          break;
        case sfpdf.PdfPageRotateAngle.rotateAngle180:
          doc.pages[i].rotation = sfpdf.PdfPageRotateAngle.rotateAngle270;
          break;
        case sfpdf.PdfPageRotateAngle.rotateAngle270:
          doc.pages[i].rotation = sfpdf.PdfPageRotateAngle.rotateAngle0;
          break;
      }
    }

    // ─── SAVE TO A NEW FILE THEN RELOAD ─────────────────────────────
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save rotated PDF',
      fileName: '${p.basenameWithoutExtension(document.name)}_rotated.pdf',
    );

    if (savePath == null) {
      doc.dispose();
      return;
    }

    final savedBytes = await doc.save();
    await File(savePath).writeAsBytes(savedBytes);
    doc.dispose();

    // ─── OPEN THE ROTATED FILE ───────────────────────────────────────
    await openFilePath(ref, savePath);
  }

  // ─── SAVE WITH ANNOTATIONS FLATTENED INTO PDF ─────────────────────────────
  static Future<void> saveWithAnnotations(
      WidgetRef ref, BuildContext context) async {
    final document = ref.read(currentDocumentProvider);
    final annotations = ref.read(annotationsProvider);

    if (document == null) return;

    // ─── PICK SAVE LOCATION ─────────────────────────────────────────────
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save PDF',
      fileName: document.name,
    );
    if (savePath == null) return;

    final bytes = File(document.path).readAsBytesSync();
    final doc = sfpdf.PdfDocument(inputBytes: bytes);

    for (final ann in annotations) {
      // ─── PAGE INDEX IS 0-BASED IN SYNCFUSION ──────────────────────────
      final pageIndex = ann.pageNumber - 1;
      if (pageIndex < 0 || pageIndex >= doc.pages.count) continue;

      final page = doc.pages[pageIndex];
      final pageHeight = page.size.height;

      // ─── CONVERT FLUTTER COORDS TO PDF COORDS ─────────────────────────
      // PDF coordinates start from bottom-left, Flutter from top-left
      final pdfRect = Rect.fromLTWH(
        ann.bounds.left,
        pageHeight - ann.bounds.top - ann.bounds.height,
        ann.bounds.width,
        ann.bounds.height,
      );

      switch (ann.type) {
        // ─── FLATTEN HIGHLIGHT ───────────────────────────────────────────
        case AnnotationType.highlight:
          final highlight = sfpdf.PdfRectangleAnnotation(
            pdfRect,
            'Highlight',
            color: sfpdf.PdfColor(
              ann.color.red,
              ann.color.green,
              ann.color.blue,
              76, // 30% opacity
            ),
            innerColor: sfpdf.PdfColor(
              ann.color.red,
              ann.color.green,
              ann.color.blue,
              76,
            ),
          );
          page.annotations.add(highlight);
          page.annotations.flattenAllAnnotations();
          break;

        // ─── FLATTEN RECTANGLE ───────────────────────────────────────────
        case AnnotationType.rectangle:
          final rect = sfpdf.PdfRectangleAnnotation(
            pdfRect,
            'Rectangle',
            color: sfpdf.PdfColor(
              ann.color.red,
              ann.color.green,
              ann.color.blue,
            ),
          );
          page.annotations.add(rect);
          page.annotations.flattenAllAnnotations();
          break;

        // ─── FLATTEN TEXT OVERLAY ────────────────────────────────────────
        case AnnotationType.text:
          if (ann.text != null) {
            page.graphics.drawString(
              ann.text!,
              sfpdf.PdfStandardFont(
                  sfpdf.PdfFontFamily.helvetica, 14),
              brush: sfpdf.PdfSolidBrush(
                sfpdf.PdfColor(
                  ann.color.red,
                  ann.color.green,
                  ann.color.blue,
                ),
              ),
              bounds: pdfRect,
            );
          }
          break;

        // ─── FLATTEN STICKY NOTE ─────────────────────────────────────────
        case AnnotationType.stickyNote:
          page.graphics.drawRectangle(
            brush: sfpdf.PdfSolidBrush(
              sfpdf.PdfColor(
                ann.color.red,
                ann.color.green,
                ann.color.blue,
                150,
              ),
            ),
            bounds: Rect.fromLTWH(
              pdfRect.left,
              pdfRect.top,
              20,
              20,
            ),
          );
          break;
      }
    }

    // ─── SAVE THE FLATTENED PDF ──────────────────────────────────────────
    final savedBytes = await doc.save();
    await File(savePath).writeAsBytes(savedBytes);
    doc.dispose();

    // ─── CLEAR ANNOTATIONS AND RELOAD ───────────────────────────────────
    ref.read(annotationsProvider.notifier).state = [];
    await openFilePath(ref, savePath);

    // ─── SHOW SUCCESS SNACKBAR ───────────────────────────────────────────
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF saved with annotations'),
          backgroundColor: Color(0xFF6C63FF),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

}