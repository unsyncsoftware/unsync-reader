class PdfDoc {
  final String path;
  final String name;
  final int pageCount;
  final DateTime openedAt;

  const PdfDoc({
    required this.path,
    required this.name,
    required this.pageCount,
    required this.openedAt,
  });

  String get fileName => name
      .replaceAll('.pdf', '')
      .replaceAll('_', ' ');
}