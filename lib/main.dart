import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'app/app.dart';
import 'models/pdf_document.dart';
import 'providers/pdf_provider.dart';
import 'services/storage_service.dart';
import 'package:path/path.dart' as p;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ─── LOAD RECENT FILES FROM DISK ───────────────────────────────────
  final savedPaths = await StorageService.loadRecentFiles();
  final recentDocs = savedPaths
      .where((path) => File(path).existsSync())
      .map((path) => PdfDoc(
            path: path,
            name: p.basename(path),
            pageCount: 0,
            openedAt: DateTime.now(),
          ))
      .toList();

  runApp(
    ProviderScope(
      overrides: [
        recentDocumentsProvider.overrideWith(
          (ref) => recentDocs,
        ),
      ],
      child: const UnsyncReaderApp(),
    ),
  );
}