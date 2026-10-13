import 'package:flutter/material.dart' hide ImageInfo;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/image_edit_settings.dart';
import '../../domain/entities/image_geometry.dart';
import 'image_editor_bloc.dart';

class ImagePropertiesPanel extends StatefulWidget {
  const ImagePropertiesPanel({required this.onExport, super.key});

  final VoidCallback onExport;

  @override
  State<ImagePropertiesPanel> createState() => _ImagePropertiesPanelState();
}

class _ImagePropertiesPanelState extends State<ImagePropertiesPanel> {
  // Live slider values while dragging; committed to history on release.
  double? _percentDrag;
  double? _brightnessDrag;
  double? _contrastDrag;
  double? _qualityDrag;

  static const _presets = <(String, int, int)>[
    ('1920 × 1080', 1920, 1080),
    ('1280 × 720', 1280, 720),
    ('800 × 600', 800, 600),
    ('512 × 512', 512, 512),
    ('256 × 256', 256, 256),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ImageEditorBloc, ImageEditorState>(
      builder: (context, state) {
        if (state.info == null) {
          return const Center(child: Text('Open an image to edit it.'));
        }
        final bloc = context.read<ImageEditorBloc>();
        final s = state.settings;
        final output = state.outputSize!;
        final info = state.info!;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Section(
              title: 'Image',
              child: Text(
                'Original ${info.width} × ${info.height} px\n'
                'Output ${output.width} × ${output.height} px',
              ),
            ),
            _Section(
              title: 'Resize',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SegmentedButton<ResizeMode>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: ResizeMode.none, label: Text('None')),
                      ButtonSegment(value: ResizeMode.percent, label: Text('%')),
                      ButtonSegment(value: ResizeMode.pixels, label: Text('Pixels')),
                    ],
                    selected: {s.resizeMode},
                    onSelectionChanged: (set) =>
                        bloc.add(ImageResizeModeChanged(set.first)),
                  ),
                  if (s.resizeMode == ResizeMode.percent) ...[
                    const SizedBox(height: 8),
                    Text('${(_percentDrag ?? s.percent).round()}%'),
                    Slider(
                      min: 1,
                      max: 200,
                      value: (_percentDrag ?? s.percent).clamp(1, 200).toDouble(),
                      onChanged: (v) => setState(() => _percentDrag = v),
                      onChangeEnd: (v) {
                        setState(() => _percentDrag = null);
                        bloc.add(ImagePercentChanged(v));
                      },
                    ),
                  ],
                  if (s.resizeMode == ResizeMode.pixels) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _NumberField(
                            label: 'Width',
                            value: output.width,
                            onSubmitted: (v) =>
                                bloc.add(ImagePixelWidthChanged(v)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _NumberField(
                            label: 'Height',
                            value: output.height,
                            onSubmitted: (v) =>
                                bloc.add(ImagePixelHeightChanged(v)),
                          ),
                        ),
                      ],
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Keep aspect ratio'),
                      value: s.lockAspect,
                      onChanged: (v) => bloc.add(ImageLockAspectChanged(v)),
                    ),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final (label, w, h) in _presets)
                          ActionChip(
                            label: Text(label),
                            onPressed: () =>
                                bloc.add(ImagePresetSelected(w, h)),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            _Section(
              title: 'Transform',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        tooltip: 'Rotate left',
                        icon: const Icon(Icons.rotate_left),
                        onPressed: () =>
                            bloc.add(const ImageRotated(clockwise: false)),
                      ),
                      IconButton(
                        tooltip: 'Rotate right',
                        icon: const Icon(Icons.rotate_right),
                        onPressed: () =>
                            bloc.add(const ImageRotated(clockwise: true)),
                      ),
                      IconButton(
                        tooltip: 'Flip horizontal',
                        icon: const Icon(Icons.swap_horiz),
                        onPressed: () => bloc.add(
                          const ImageFlipped(horizontal: true),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Flip vertical',
                        icon: const Icon(Icons.swap_vert),
                        onPressed: () => bloc.add(
                          const ImageFlipped(horizontal: false),
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 6,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.crop_square),
                        label: const Text('Center square'),
                        onPressed: () => bloc.add(
                          ImageCropChanged(_centerSquare(info)),
                        ),
                      ),
                      if (s.crop != null)
                        TextButton(
                          onPressed: () =>
                              bloc.add(const ImageCropChanged(null)),
                          child: const Text('Clear crop'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            _Section(
              title: 'Adjustments',
              child: Column(
                children: [
                  _labeledSlider(
                    'Brightness',
                    (_brightnessDrag ?? s.brightness.toDouble()),
                    (v) => setState(() => _brightnessDrag = v),
                    (v) {
                      setState(() => _brightnessDrag = null);
                      bloc.add(ImageAdjustmentsChanged(brightness: v.round()));
                    },
                  ),
                  _labeledSlider(
                    'Contrast',
                    (_contrastDrag ?? s.contrast.toDouble()),
                    (v) => setState(() => _contrastDrag = v),
                    (v) {
                      setState(() => _contrastDrag = null);
                      bloc.add(ImageAdjustmentsChanged(contrast: v.round()));
                    },
                  ),
                ],
              ),
            ),
            _Section(
              title: 'Output',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InputDecorator(
                    decoration: const InputDecoration(labelText: 'Format'),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<OutputFormat>(
                        value: s.format,
                        isExpanded: true,
                        items: [
                          for (final f in OutputFormat.values)
                            DropdownMenuItem(value: f, child: Text(f.label)),
                        ],
                        onChanged: (f) {
                          if (f != null) bloc.add(ImageFormatChanged(format: f));
                        },
                      ),
                    ),
                  ),
                  if (s.format.supportsQuality)
                    _labeledSlider(
                      'Quality',
                      (_qualityDrag ?? s.quality.toDouble()),
                      (v) => setState(() => _qualityDrag = v),
                      (v) {
                        setState(() => _qualityDrag = null);
                        bloc.add(ImageFormatChanged(quality: v.round()));
                      },
                      min: 1,
                      max: 100,
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'WebP export is not available: the pure-Dart encoder does not support it.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (state.exporting) const LinearProgressIndicator(),
            FilledButton.icon(
              icon: const Icon(Icons.save_alt),
              label: const Text('Export…'),
              onPressed: state.exporting ? null : widget.onExport,
            ),
            if (state.lastExport != null) ...[
              const SizedBox(height: 8),
              Text(
                'Last export: ${state.lastExport!.width} × ${state.lastExport!.height} px, '
                '${_formatBytes(state.lastExport!.sizeBytes)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        );
      },
    );
  }

  CropRect _centerSquare(ImageInfo info) {
    final side = info.width < info.height ? info.width : info.height;
    return CropRect(
      x: (info.width - side) ~/ 2,
      y: (info.height - side) ~/ 2,
      width: side,
      height: side,
    );
  }

  Widget _labeledSlider(
    String label,
    double value,
    ValueChanged<double> onChanged,
    ValueChanged<double> onChangeEnd, {
    double min = -100,
    double max = 100,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.round()}'),
        Slider(
          min: min,
          max: max,
          value: value.clamp(min, max).toDouble(),
          onChanged: onChanged,
          onChangeEnd: onChangeEnd,
        ),
      ],
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// Keeps its text in sync with [value] unless the user is typing.
class _NumberField extends StatefulWidget {
  const _NumberField({
    required this.label,
    required this.value,
    required this.onSubmitted,
  });

  final String label;
  final int value;
  final ValueChanged<int> onSubmitted;

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late final TextEditingController _controller;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.value}');
    _focus.addListener(() {
      if (!_focus.hasFocus) _submit();
    });
  }

  @override
  void didUpdateWidget(covariant _NumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focus.hasFocus && oldWidget.value != widget.value) {
      _controller.text = '${widget.value}';
    }
  }

  void _submit() {
    final parsed = int.tryParse(_controller.text);
    if (parsed != null && parsed > 0 && parsed != widget.value) {
      widget.onSubmitted(parsed);
    } else {
      _controller.text = '${widget.value}';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focus,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: widget.label, suffixText: 'px'),
      onSubmitted: (_) => _submit(),
    );
  }
}
