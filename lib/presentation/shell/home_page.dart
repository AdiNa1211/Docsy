import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;

import '../../core/di/injection.dart';
import '../../domain/entities/file_kind.dart';
import '../../domain/entities/opened_file.dart';
import '../../domain/usecases/export_image_usecase.dart';
import '../batch/batch_resize_cubit.dart';
import '../batch/batch_resize_page.dart';
import '../conversion/conversion_cubit.dart';
import '../conversion/conversion_panel.dart';
import '../document_editor/document_editor_cubit.dart';
import '../document_editor/pdf_workspace.dart';
import '../document_editor/text_workspace.dart';
import '../file_manager/file_manager_cubit.dart';
import '../image_editor/image_editor_bloc.dart';
import '../image_editor/image_properties_panel.dart';
import '../image_editor/image_workspace.dart';
import '../settings/app_settings_cubit.dart';
import 'app_sidebar.dart';
import 'confirm_dialog.dart';
import 'native_dialogs.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<FileManagerCubit>()),
        BlocProvider(create: (_) => sl<ImageEditorBloc>()),
        BlocProvider(create: (_) => sl<DocumentEditorCubit>()),
        BlocProvider(create: (_) => sl<ConversionCubit>()),
        BlocProvider(create: (_) => sl<BatchResizeCubit>()),
      ],
      child: const _HomeView(),
    );
  }
}

enum _View { editor, batch }

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  static const _sidebarWidth = 220.0;
  static const _propertiesWidth = 300.0;
  static const _propertiesBreakpoint = 1000.0;

  _View _view = _View.editor;
  bool _dragging = false;
  bool _originalConfirmed = false;

  OpenedFile? get _file => context.read<FileManagerCubit>().state.current;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<FileManagerCubit, FileManagerState>(
          listenWhen: (p, c) => c.current != null && c.current != p.current,
          listener: (_, s) => _onFileOpened(s.current!),
        ),
        BlocListener<FileManagerCubit, FileManagerState>(
          listenWhen: (p, c) => c.message != null && c.message != p.message,
          listener: (_, s) => _snack(s.message!),
        ),
        BlocListener<ImageEditorBloc, ImageEditorState>(
          listenWhen: (p, c) =>
              c.overwritePrompt != null && c.overwritePrompt != p.overwritePrompt,
          listener: (_, s) => _confirmImageOverwrite(s.overwritePrompt!),
        ),
        BlocListener<ImageEditorBloc, ImageEditorState>(
          listenWhen: (p, c) =>
              c.lastExport != null && c.lastExport != p.lastExport,
          listener: (_, s) => _snack('Saved ${p.basename(s.lastExport!.path)}'),
        ),
        BlocListener<ImageEditorBloc, ImageEditorState>(
          listenWhen: (p, c) => c.message != null && c.message != p.message,
          listener: (_, s) => _snack(s.message!),
        ),
        BlocListener<DocumentEditorCubit, DocumentEditorState>(
          listenWhen: (p, c) => c.message != null && c.message != p.message,
          listener: (_, s) => _snack(s.message!),
        ),
        BlocListener<ConversionCubit, ConversionState>(
          listenWhen: (p, c) =>
              c.status == ConversionStatus.overwriteRequired &&
              p.status != c.status,
          listener: (_, s) => _confirmConversionOverwrite(s.outputPath!),
        ),
      ],
      child: CallbackShortcuts(
        bindings: _shortcuts(),
        child: Focus(
          autofocus: true,
          child: Scaffold(
            appBar: _buildAppBar(),
            body: DropTarget(
              onDragEntered: (_) => setState(() => _dragging = true),
              onDragExited: (_) => setState(() => _dragging = false),
              onDragDone: (details) {
                setState(() => _dragging = false);
                if (details.files.isNotEmpty) {
                  _openPath(details.files.first.path);
                }
              },
              child: Stack(
                children: [
                  _buildBody(),
                  if (_dragging) _dropOverlay(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: BlocBuilder<FileManagerCubit, FileManagerState>(
        builder: (context, state) {
          final name = state.current?.name ?? 'Docsy';
          return Text(name, overflow: TextOverflow.ellipsis);
        },
      ),
      actions: [
        IconButton(
          tooltip: 'Open (Ctrl+O)',
          icon: const Icon(Icons.folder_open),
          onPressed: _openDialog,
        ),
        IconButton(
          tooltip: 'Save (Ctrl+S)',
          icon: const Icon(Icons.save),
          onPressed: _save,
        ),
        IconButton(
          tooltip: 'Save As (Ctrl+Shift+S)',
          icon: const Icon(Icons.save_as),
          onPressed: _saveAs,
        ),
        IconButton(
          tooltip: 'Export',
          icon: const Icon(Icons.file_download_outlined),
          onPressed: _export,
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Undo (Ctrl+Z)',
          icon: const Icon(Icons.undo),
          onPressed: _undo,
        ),
        IconButton(
          tooltip: 'Redo (Ctrl+Shift+Z)',
          icon: const Icon(Icons.redo),
          onPressed: _redo,
        ),
        const SizedBox(width: 8),
        BlocBuilder<AppSettingsCubit, AppSettingsState>(
          builder: (context, settings) {
            final dark = Theme.of(context).brightness == Brightness.dark;
            return IconButton(
              tooltip: 'Toggle theme',
              icon: Icon(dark ? Icons.light_mode : Icons.dark_mode),
              onPressed: () => context.read<AppSettingsCubit>().toggleTheme(
                Theme.of(context).brightness,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBody() {
    return BlocBuilder<FileManagerCubit, FileManagerState>(
      builder: (context, fileState) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final showProperties =
                _view == _View.editor &&
                fileState.current != null &&
                constraints.maxWidth >= _propertiesBreakpoint;
            return Row(
              children: [
                SizedBox(
                  width: _sidebarWidth,
                  child: AppSidebar(
                    recent: fileState.recent,
                    currentPath: fileState.current?.path,
                    batchActive: _view == _View.batch,
                    onOpen: _openDialog,
                    onOpenRecent: _openPath,
                    onShowFiles: () => setState(() => _view = _View.editor),
                    onShowBatch: () => setState(() => _view = _View.batch),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: _buildWorkspace(fileState.current)),
                if (showProperties) ...[
                  const VerticalDivider(width: 1),
                  SizedBox(
                    width: _propertiesWidth,
                    child: _buildProperties(fileState.current!),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildWorkspace(OpenedFile? file) {
    if (_view == _View.batch) return const BatchResizePage();
    if (file == null) return _EmptyState(onOpen: _openDialog);
    if (file.kind.isImage) return const ImageWorkspace();
    return switch (file.kind) {
      FileKind.txt => const TextWorkspace(),
      FileKind.pdf => PdfWorkspace(path: file.path),
      FileKind.docx || FileKind.doc || FileKind.rtf => ConversionPanel(
        fileName: file.name,
        onConvert: _convertToPdf,
        onOpenResult: _openPath,
      ),
      _ => _EmptyState(onOpen: _openDialog),
    };
  }

  Widget _buildProperties(OpenedFile file) {
    if (file.kind.isImage) {
      return ImagePropertiesPanel(onExport: _exportImageDialog);
    }
    return _FileInfoPanel(file: file);
  }

  Widget _dropOverlay(BuildContext context) {
    return IgnorePointer(
      child: ColoredBox(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
        child: Center(
          child: Text(
            'Drop file to open',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
      ),
    );
  }

  Map<ShortcutActivator, VoidCallback> _shortcuts() {
    final map = <ShortcutActivator, VoidCallback>{};
    void bind(LogicalKeyboardKey key, VoidCallback action, {bool shift = false}) {
      map[SingleActivator(key, control: true, shift: shift)] = action;
      map[SingleActivator(key, meta: true, shift: shift)] = action;
    }

    bind(LogicalKeyboardKey.keyO, _openDialog);
    bind(LogicalKeyboardKey.keyS, _save);
    bind(LogicalKeyboardKey.keyS, _saveAs, shift: true);
    bind(LogicalKeyboardKey.keyZ, _undo);
    bind(LogicalKeyboardKey.keyZ, _redo, shift: true);
    bind(LogicalKeyboardKey.keyY, _redo);
    return map;
  }

  void _onFileOpened(OpenedFile file) {
    setState(() {
      _view = _View.editor;
      _originalConfirmed = false;
    });
    context.read<ConversionCubit>().reset();
    if (file.kind.isImage) {
      context.read<ImageEditorBloc>().add(ImageOpened(file.path));
    } else if (file.kind == FileKind.txt) {
      context.read<DocumentEditorCubit>().load(file.path);
    }
  }

  Future<void> _openDialog() async {
    final path = await NativeDialogs.openDocumentOrImage();
    if (path != null) await _openPath(path);
  }

  Future<void> _openPath(String path) async {
    if (!await _confirmDiscardChanges()) return;
    if (!mounted) return;
    context.read<FileManagerCubit>().openPath(path);
  }

  Future<bool> _confirmDiscardChanges() async {
    final doc = context.read<DocumentEditorCubit>().state;
    final image = context.read<ImageEditorBloc>().state;
    final unsaved = doc.isDirty || (image.file != null && image.canUndo);
    if (!unsaved) return true;
    if (!mounted) return false;
    return showConfirmDialog(
      context,
      title: 'Discard unsaved changes?',
      message: 'Changes to the current file have not been saved.',
      confirmLabel: 'Discard',
      destructive: true,
    );
  }

  Future<void> _save() async {
    final file = _file;
    if (file == null) return;
    if (file.kind.isImage) {
      final settings = context.read<ImageEditorBloc>().state.settings;
      context.read<ImageEditorBloc>().add(
        ImageExportRequested(
          destination: outputPathFor(
            file.path,
            file.directory,
            settings.format,
          ),
        ),
      );
      return;
    }
    if (file.kind == FileKind.txt) {
      if (!_originalConfirmed) {
        final ok = await _confirmOverwriteOriginal(file);
        if (!ok || !mounted) return;
        _originalConfirmed = true;
      }
      await context.read<DocumentEditorCubit>().save();
      return;
    }
    _snack('Save is not available for this file. Use Export to convert it.');
  }

  Future<void> _saveAs() async {
    final file = _file;
    if (file == null) return;
    if (file.kind.isImage) return _exportImageDialog();
    if (file.kind == FileKind.txt) {
      final target = await NativeDialogs.saveAs(
        suggestedName: file.name,
        extension: 'txt',
      );
      if (target == null || !mounted) return;
      await context.read<DocumentEditorCubit>().save(target: target);
      return;
    }
    _snack('Save As is available for text and image files.');
  }

  Future<void> _export() async {
    final file = _file;
    if (file == null) return;
    if (file.kind.isImage) return _exportImageDialog();
    if (file.kind.isDocument && file.kind != FileKind.txt && file.kind != FileKind.pdf) {
      return _convertToPdf();
    }
    _snack('Export is available for images and Word documents.');
  }

  Future<void> _exportImageDialog() async {
    final bloc = context.read<ImageEditorBloc>();
    final file = bloc.state.file;
    if (file == null) return;
    final ext = bloc.state.settings.format.extension;
    final path = await NativeDialogs.saveAs(
      suggestedName: '${file.baseName}_resized.$ext',
      extension: ext,
    );
    if (path == null) return;
    bloc.add(ImageExportRequested(destination: path));
  }

  Future<void> _convertToPdf() async {
    final file = _file;
    if (file == null) return;
    final destination = await NativeDialogs.saveAs(
      suggestedName: '${file.baseName}.pdf',
      extension: 'pdf',
    );
    if (destination == null || !mounted) return;
    await context.read<ConversionCubit>().convertToPdf(
      source: file.path,
      destination: destination,
    );
  }

  Future<void> _confirmImageOverwrite(String destination) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Replace existing file?',
      message: '${p.basename(destination)} already exists. Replace it?',
      confirmLabel: 'Replace',
      destructive: true,
    );
    if (ok && mounted) {
      context.read<ImageEditorBloc>().add(
        ImageExportRequested(destination: destination, overwrite: true),
      );
    }
  }

  Future<void> _confirmConversionOverwrite(String destination) async {
    final source = _file?.path;
    final ok = await showConfirmDialog(
      context,
      title: 'Replace existing PDF?',
      message: '${p.basename(destination)} already exists. Replace it?',
      confirmLabel: 'Replace',
      destructive: true,
    );
    if (ok && mounted && source != null) {
      await context.read<ConversionCubit>().convertToPdf(
        source: source,
        destination: destination,
        overwrite: true,
      );
    }
  }

  Future<bool> _confirmOverwriteOriginal(OpenedFile file) =>
      showConfirmDialog(
        context,
        title: 'Overwrite original file?',
        message:
            'Saving replaces ${file.name} on disk. Use Save As to keep the original.',
        confirmLabel: 'Save',
        destructive: true,
      );

  void _undo() {
    final file = _file;
    if (file == null) return;
    if (file.kind.isImage) {
      context.read<ImageEditorBloc>().add(const ImageUndoRequested());
    } else if (file.kind == FileKind.txt) {
      context.read<DocumentEditorCubit>().undo();
    }
  }

  void _redo() {
    final file = _file;
    if (file == null) return;
    if (file.kind.isImage) {
      context.read<ImageEditorBloc>().add(const ImageRedoRequested());
    } else if (file.kind == FileKind.txt) {
      context.read<DocumentEditorCubit>().redo();
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.drive_folder_upload_outlined,
            size: 64,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text('Drop a file here or open one', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'PDF, TXT, DOC, DOCX, RTF and common image formats',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.folder_open),
            label: const Text('Open file…'),
            onPressed: onOpen,
          ),
        ],
      ),
    );
  }
}

class _FileInfoPanel extends StatelessWidget {
  const _FileInfoPanel({required this.file});

  final OpenedFile file;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('File', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Text(file.name),
        Text(file.directory, style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        Text('Type: ${file.kind.name.toUpperCase()}'),
        Text('Size: ${_formatBytes(file.sizeBytes)}'),
        if (file.kind == FileKind.txt) ...[
          const SizedBox(height: 16),
          BlocBuilder<DocumentEditorCubit, DocumentEditorState>(
            builder: (context, state) {
              final words = state.text.trim().isEmpty
                  ? 0
                  : state.text.trim().split(RegExp(r'\s+')).length;
              return Text(
                'Words: $words\nCharacters: ${state.text.length}\n'
                'Encoding: ${state.encoding.name}\n'
                '${state.isDirty ? 'Unsaved changes' : 'All changes saved'}',
              );
            },
          ),
        ],
        if (file.kind == FileKind.pdf) ...[
          const SizedBox(height: 16),
          const Text(
            'PDF viewing only. Editing and annotation are not part of this version.',
          ),
        ],
      ],
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
