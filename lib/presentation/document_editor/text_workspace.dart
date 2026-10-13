import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'document_editor_cubit.dart';

class TextWorkspace extends StatefulWidget {
  const TextWorkspace({super.key});

  @override
  State<TextWorkspace> createState() => _TextWorkspaceState();
}

class _TextWorkspaceState extends State<TextWorkspace> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DocumentEditorCubit, DocumentEditorState>(
      // Pushes undo/redo results into the field without echoing typed text back.
      listenWhen: (_, state) => state.text != _controller.text,
      listener: (context, state) {
        _controller.value = TextEditingValue(
          text: state.text,
          selection: TextSelection.collapsed(offset: state.text.length),
        );
      },
      child: BlocBuilder<DocumentEditorCubit, DocumentEditorState>(
        buildWhen: (p, c) => p.loading != c.loading,
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              expands: true,
              maxLines: null,
              minLines: null,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(fontFamily: 'monospace', height: 1.4),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              onChanged: context.read<DocumentEditorCubit>().edit,
            ),
          );
        },
      ),
    );
  }
}
