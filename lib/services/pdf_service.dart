import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:syncfusion_flutter_pdf/pdf.dart' as sfpdf;
import '../models/pdf_document.dart';
import '../providers/pdf_provider.dart';
import 'package:flutter/material.dart';

class PdfService {

  static Future<void> openFile(WidgetRef ref) async {
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
    ref.read(recentDocumentsProvider.notifier).state =
        recents.take(10).toList();
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

  static Future<void> pdfToImages(WidgetRef ref) async {
    // TODO: implement via pdfrx rasterization
  }

  static Future<void> rotatePages(WidgetRef ref) async {
    final document = ref.read(currentDocumentProvider);
    if (document == null) return;

    final bytes = File(document.path).readAsBytesSync();
    final doc = sfpdf.PdfDocument(inputBytes: bytes);

    for (int i = 0; i < doc.pages.count; i++) {
      doc.pages[i].rotation =
          doc.pages[i].rotation == sfpdf.PdfPageRotateAngle.rotateAngle270
              ? sfpdf.PdfPageRotateAngle.rotateAngle0
              : sfpdf.PdfPageRotateAngle.values[
                  doc.pages[i].rotation.index + 1];
    }

    await File(document.path).writeAsBytes(await doc.save());
    doc.dispose();
    await openFilePath(ref, document.path);
  }
}