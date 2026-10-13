import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

/// Read-only PDF viewer. Zoom, pan and page navigation come from pdfrx.
/// Editing and annotation are not implemented in this phase.
class PdfWorkspace extends StatelessWidget {
  const PdfWorkspace({required this.path, super.key});

  final String path;

  @override
  Widget build(BuildContext context) {
    return PdfViewer.file(
      path,
      key: ValueKey(path),
      params: const PdfViewerParams(),
    );
  }
}
