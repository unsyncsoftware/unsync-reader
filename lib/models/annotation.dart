import 'package:flutter/material.dart';

// ─── ANNOTATION TYPES ─────────────────────────────────────────────────────
enum AnnotationType { highlight, text, rectangle, stickyNote }

class Annotation {
  final String id;
  final AnnotationType type;
  final int pageNumber;
  final Rect bounds;        // position on the page in PDF coordinates
  final String? text;       // for text overlay and sticky notes
  final Color color;

  const Annotation({
    required this.id,
    required this.type,
    required this.pageNumber,
    required this.bounds,
    this.text,
    required this.color,
  });

  Annotation copyWith({
    String? text,
    Rect? bounds,
    Color? color,
  }) {
    return Annotation(
      id: id,
      type: type,
      pageNumber: pageNumber,
      bounds: bounds ?? this.bounds,
      text: text ?? this.text,
      color: color ?? this.color,
    );
  }
}