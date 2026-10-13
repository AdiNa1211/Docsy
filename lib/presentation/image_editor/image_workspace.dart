import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/image_geometry.dart';
import 'image_editor_bloc.dart';

/// Side-by-side original and output preview with synced zoom and pan.
class ImageWorkspace extends StatefulWidget {
  const ImageWorkspace({super.key});

  @override
  State<ImageWorkspace> createState() => _ImageWorkspaceState();
}

class _ImageWorkspaceState extends State<ImageWorkspace> {
  final _originalZoom = TransformationController();
  final _outputZoom = TransformationController();

  @override
  void dispose() {
    _originalZoom.dispose();
    _outputZoom.dispose();
    super.dispose();
  }

  void _zoom(double factor) {
    for (final c in [_originalZoom, _outputZoom]) {
      c.value = c.value.clone()..scale(factor);
    }
  }

  void _fit() {
    _originalZoom.value = Matrix4.identity();
    _outputZoom.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ImageEditorBloc, ImageEditorState>(
      builder: (context, state) {
        final file = state.file;
        return Column(
          children: [
            _ZoomBar(
              onZoomIn: () => _zoom(1.25),
              onZoomOut: () => _zoom(0.8),
              onFit: _fit,
            ),
            const Divider(height: 1),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _Pane(
                      title: 'Original'
                          '${state.info == null ? '' : '  ${state.info!.width}×${state.info!.height}'}',
                      controller: _originalZoom,
                      child: file == null
                          ? const SizedBox.shrink()
                          : Image.file(
                              File(file.path),
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.medium,
                            ),
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: _Pane(
                      title: 'Output'
                          '${state.outputSize == null ? '' : '  ${state.outputSize!.width}×${state.outputSize!.height}'}',
                      busy: state.previewBusy,
                      controller: _outputZoom,
                      child: state.previewBytes == null
                          ? const SizedBox.shrink()
                          : Image.memory(
                              state.previewBytes!,
                              fit: BoxFit.contain,
                              gaplessPlayback: true,
                              filterQuality: FilterQuality.medium,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ZoomBar extends StatelessWidget {
  const _ZoomBar({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onFit,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onFit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Tooltip(
            message: 'Zoom out',
            child: IconButton(
              icon: const Icon(Icons.zoom_out),
              onPressed: onZoomOut,
            ),
          ),
          Tooltip(
            message: 'Zoom in',
            child: IconButton(
              icon: const Icon(Icons.zoom_in),
              onPressed: onZoomIn,
            ),
          ),
          Tooltip(
            message: 'Fit to screen',
            child: IconButton(
              icon: const Icon(Icons.fit_screen),
              onPressed: onFit,
            ),
          ),
          const Spacer(),
          Text(
            'Drag to pan · scroll or pinch to zoom',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _Pane extends StatelessWidget {
  const _Pane({
    required this.title,
    required this.controller,
    required this.child,
    this.busy = false,
  });

  final String title;
  final TransformationController controller;
  final Widget child;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (busy)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
        Expanded(
          child: ClipRect(
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              child: LayoutBuilder(
                builder: (context, constraints) => InteractiveViewer(
                  transformationController: controller,
                  minScale: 0.1,
                  maxScale: 8,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
