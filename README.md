# Docsy

A desktop document and image editor for Windows, macOS and Linux, built with Flutter.

> **Status: phase 1 code written, not yet compiled.** The code was written without access to the Flutter SDK or pub.dev. Run `flutter analyze` and `flutter test` before relying on it.

## Setup

Requirements:

- Flutter stable with desktop support enabled for your OS (`flutter config --enable-macos-desktop` / `--enable-windows-desktop` / `--enable-linux-desktop`)
- LibreOffice, for DOC, DOCX and RTF conversion
  - macOS: `/Applications/LibreOffice.app`
  - Windows: `C:\Program Files\LibreOffice\program\soffice.exe`
  - Linux: `soffice` on PATH

```bash
cd desk
flutter pub get
flutter analyze
flutter test
flutter run -d macos    # or windows / linux
```

The first build downloads PDFium through pdfrx, so it needs network access.

### Build

```bash
flutter build macos
flutter build windows
flutter build linux
```

## Architecture

```
lib/
  core/            DI (get_it), errors, theme, text codec, limits, cancellation
  domain/          entities, repository interfaces, use cases (no Flutter imports)
  data/            file access, image processing (isolate), LibreOffice converter
  presentation/    blocs/cubits, screens and widgets, grouped by feature
```

State management is `flutter_bloc` only: `ImageEditorBloc` for the image pipeline, cubits for the file manager, text editor, batch and conversion, and settings.

## Done

- [x] Project structure, Clean Architecture layers and `get_it` wiring
- [x] Desktop shell: sidebar (open, recent files, tools), toolbar, properties panel, drag-and-drop, light and dark themes
- [x] Keyboard shortcuts: Open, Save, Save As, Undo, Redo (Ctrl on Windows and Linux, Cmd on macOS)
- [x] Unsaved-change guard when switching files; overwrite confirmation for original text files and existing exports
- [x] Image editor
  - [x] Resize by pixels, percent or presets, with aspect lock
  - [x] Center-square crop, rotate, flip
  - [x] Brightness and contrast
  - [x] Export to PNG, JPEG (with quality) and BMP
  - [x] Undo and redo, debounced restartable previews
  - [x] Before and after view with zoom and pan
  - [x] Export never overwrites the source image
- [x] Batch resize: shared settings, output folder, collision-safe names, progress, stop
- [x] Plain text (TXT): editing, undo and redo, encoding preserved (UTF-8, BOM, Latin-1)
- [x] PDF viewing (read-only, pdfrx)
- [x] DOC, DOCX and RTF converted to PDF with LibreOffice headless, written to a temp folder and then saved where you choose
- [x] Unit tests: text codec, file kinds, resize geometry, image processing output, export use case
- [x] Bloc and cubit tests: image editor, document editor
- [x] Widget test: conversion panel

## Not yet done

### Verification (highest priority)

- [ ] `flutter pub get`, `flutter analyze` and `flutter test` pass
- [ ] Confirm package versions in `pubspec.yaml` and their licences (bloc, get_it, image, file_picker, desktop_drop, pdfrx)
- [ ] Confirm `image` package API calls: `encodeBmp`, `flip`, `compositeImage`, pixel setters
- [ ] Manual test pass on macOS, Windows and Linux: open, resize, export, convert, drag-and-drop, shortcuts

### Platform setup

- [ ] macOS: confirm sandbox entitlements allow user-selected read and write (`macos/Runner/*.entitlements`)
- [ ] Windows and Linux: check file dialog and LibreOffice path detection on real machines

### Document editing (phase 2)

- [ ] DOCX editing: basic formatting (font, size, bold, italic, underline, alignment, lists) written back to the file, or a documented decision not to support it
- [ ] RTF editing and save
- [ ] Clearly separate "edit existing PDF text" from "annotations and overlays"

### PDF (phase 2)

- [ ] Annotations, highlights, shapes and image overlays
- [ ] Rotate, reorder, delete, merge and split pages
- [ ] Save modifications as PDF, preserving content where possible

### Image editor

- [ ] Numeric crop (x, y, width, height) with on-canvas handles
- [ ] Before and after toggle and split slider, in addition to side-by-side
- [ ] Estimated output file size before export

### Batch and conversion

- [ ] Batch cancellation test coverage
- [ ] Warn before conversion when formatting may be lost (message shown after, not before)
- [ ] Conversion progress percentage (currently indeterminate)

### App behaviour

- [ ] Persist recent files across launches
- [ ] Hide the properties panel below 1000 px and offer a way to reopen it
- [ ] Large-file warnings in the UI (hard limit is 500 MB)
- [ ] Disk-space and permission errors shown with clear next steps

### Known limitations (by design for now)

- WebP export is not available: the pure-Dart `image` package has no WebP encoder. WebP files can be opened and GIF and TIFF can be read, but these formats cannot be exported.
- Image undo and redo track settings changes, not pixel buffers.
- Text undo coalesces typing bursts within one second.

## Decisions

- Image processing runs in an isolate. Previews are downscaled to 1024 px on the longest side. Export always uses full resolution.
- Writes are atomic: data goes to a temp file, which is then renamed.
- Original files are never written to without explicit confirmation. Image export always goes to a new name by default.
- LibreOffice runs with a private profile and output directory, never next to the input.
- Tests cover real behaviour (actual pixel output, encoding round-trips) rather than only mocks.
