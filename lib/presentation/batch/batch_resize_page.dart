import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;

import '../../domain/entities/image_edit_settings.dart';
import '../../domain/usecases/batch_resize_usecase.dart';
import '../shell/native_dialogs.dart';
import 'batch_resize_cubit.dart';

class BatchResizePage extends StatelessWidget {
  const BatchResizePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BatchResizeCubit, BatchResizeState>(
      builder: (context, state) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 720;
            final files = _FileList(state: state);
            final settings = _BatchSettings(state: state);
            return Padding(
              padding: const EdgeInsets.all(16),
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: files),
                        const SizedBox(width: 16),
                        SizedBox(width: 320, child: settings),
                      ],
                    )
                  : Column(
                      children: [
                        Expanded(child: files),
                        const SizedBox(height: 16),
                        Expanded(child: settings),
                      ],
                    ),
            );
          },
        );
      },
    );
  }
}

class _FileList extends StatelessWidget {
  const _FileList({required this.state});

  final BatchResizeState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BatchResizeCubit>();
    final resultsByPath = {for (final r in state.results) r.source: r};
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Images (${state.sources.length})',
              style: theme.textTheme.titleMedium,
            ),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Add images'),
              onPressed: state.running
                  ? null
                  : () async {
                      cubit.addSources(await NativeDialogs.openImages());
                    },
            ),
            TextButton(
              onPressed: state.running || state.sources.isEmpty
                  ? null
                  : cubit.clearSources,
              child: const Text('Clear'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: state.sources.isEmpty
              ? const Center(child: Text('Add images to resize them together.'))
              : ListView.builder(
                  itemCount: state.sources.length,
                  itemBuilder: (context, index) {
                    final path = state.sources[index];
                    final result = resultsByPath[path];
                    return ListTile(
                      dense: true,
                      leading: _statusIcon(result, theme),
                      title: Text(p.basename(path)),
                      subtitle: _subtitle(result),
                      trailing: IconButton(
                        tooltip: 'Remove',
                        icon: const Icon(Icons.close),
                        onPressed: state.running
                            ? null
                            : () => cubit.removeSource(path),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _statusIcon(BatchItemResult? result, ThemeData theme) {
    if (result == null) return const Icon(Icons.image_outlined);
    return result.succeeded
        ? const Icon(Icons.check_circle_outline, color: Colors.green)
        : Icon(Icons.error_outline, color: theme.colorScheme.error);
  }

  Widget? _subtitle(BatchItemResult? result) {
    if (result == null) return null;
    if (result.error != null) return Text(result.error!, maxLines: 2);
    return Text('Saved ${p.basename(result.output!)}');
  }
}

class _BatchSettings extends StatefulWidget {
  const _BatchSettings({required this.state});

  final BatchResizeState state;

  @override
  State<_BatchSettings> createState() => _BatchSettingsState();
}

class _BatchSettingsState extends State<_BatchSettings> {
  final _percent = TextEditingController(text: '50');
  final _width = TextEditingController();
  final _height = TextEditingController();

  @override
  void dispose() {
    _percent.dispose();
    _width.dispose();
    _height.dispose();
    super.dispose();
  }

  void _apply(ImageEditSettings next) =>
      context.read<BatchResizeCubit>().setSettings(next);

  /// Keep-aspect means height stays unset, so each image derives it from its own ratio.
  void _setLock(ImageEditSettings s, bool locked) {
    if (locked) {
      _height.clear();
      _apply(s.copyWith(clearSize: true).copyWith(lockAspect: true, width: s.width));
    } else {
      _apply(s.copyWith(lockAspect: false, height: s.height ?? s.width));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BatchResizeCubit>();
    final state = widget.state;
    final s = state.settings;
    final busy = state.running;
    final pixels = s.resizeMode == ResizeMode.pixels;

    return ListView(
      children: [
        Text('Shared settings', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        SegmentedButton<ResizeMode>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: ResizeMode.percent, label: Text('Percent')),
            ButtonSegment(value: ResizeMode.pixels, label: Text('Pixels')),
          ],
          selected: {pixels ? ResizeMode.pixels : ResizeMode.percent},
          onSelectionChanged: busy
              ? null
              : (set) => _apply(s.copyWith(resizeMode: set.first)),
        ),
        const SizedBox(height: 12),
        if (!pixels)
          TextField(
            controller: _percent,
            enabled: !busy,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Percent',
              suffixText: '%',
            ),
            onSubmitted: (v) {
              final parsed = double.tryParse(v);
              if (parsed != null && parsed > 0) {
                _apply(
                  s.copyWith(resizeMode: ResizeMode.percent, percent: parsed),
                );
              }
            },
          )
        else ...[
          TextField(
            controller: _width,
            enabled: !busy,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Width', suffixText: 'px'),
            onSubmitted: (v) {
              final parsed = int.tryParse(v);
              if (parsed != null && parsed > 0) {
                _apply(s.copyWith(width: parsed));
              }
            },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _height,
            enabled: !busy && !s.lockAspect,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Height',
              suffixText: 'px',
            ),
            onSubmitted: (v) {
              final parsed = int.tryParse(v);
              if (parsed != null && parsed > 0) {
                _apply(s.copyWith(height: parsed));
              }
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Keep each image’s aspect ratio'),
            value: s.lockAspect,
            onChanged: busy ? null : (v) => _setLock(s, v),
          ),
        ],
        const SizedBox(height: 12),
        DropdownButtonFormField<OutputFormat>(
          key: ValueKey(s.format),
          initialValue: s.format,
          decoration: const InputDecoration(labelText: 'Format'),
          items: [
            for (final f in OutputFormat.values)
              DropdownMenuItem(value: f, child: Text(f.label)),
          ],
          onChanged: busy ? null : (f) => _apply(s.copyWith(format: f)),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          icon: const Icon(Icons.folder_open),
          label: Text(
            state.outputDirectory == null
                ? 'Choose output folder'
                : p.basename(state.outputDirectory!),
          ),
          onPressed: busy
              ? null
              : () async {
                  final dir = await NativeDialogs.chooseFolder();
                  if (dir != null) cubit.setOutputDirectory(dir);
                },
        ),
        const SizedBox(height: 16),
        if (busy) ...[
          LinearProgressIndicator(value: state.progress),
          const SizedBox(height: 4),
          Text('${state.processed} of ${state.sources.length}'),
          TextButton(onPressed: cubit.cancel, child: const Text('Stop')),
        ] else
          FilledButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text('Run batch'),
            onPressed: state.sources.isEmpty || state.outputDirectory == null
                ? null
                : cubit.run,
          ),
        if (state.message != null) ...[
          const SizedBox(height: 12),
          Text(state.message!),
        ],
      ],
    );
  }
}
