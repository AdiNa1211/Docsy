import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'conversion_cubit.dart';

/// Shown for DOC/DOCX/RTF files, which are not editable in this phase.
class ConversionPanel extends StatelessWidget {
  const ConversionPanel({
    required this.fileName,
    required this.onConvert,
    required this.onOpenResult,
    super.key,
  });

  final String fileName;
  final VoidCallback onConvert;
  final void Function(String pdfPath) onOpenResult;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: BlocBuilder<ConversionCubit, ConversionState>(
            builder: (context, state) {
              final converting = state.status == ConversionStatus.converting;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fileName, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  const Text(
                    'Word documents are not editable in this version. Convert to PDF to view or share '
                    'them. Conversion uses LibreOffice, which must be installed. Formatting may change.',
                  ),
                  const SizedBox(height: 16),
                  if (converting) ...[
                    const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context.read<ConversionCubit>().cancel(),
                      child: const Text('Cancel conversion'),
                    ),
                  ] else
                    FilledButton.icon(
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Convert to PDF…'),
                      onPressed: onConvert,
                    ),
                  if (state.message != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      state.message!,
                      style: TextStyle(
                        color: state.status == ConversionStatus.failure
                            ? theme.colorScheme.error
                            : null,
                      ),
                    ),
                  ],
                  if (state.status == ConversionStatus.done &&
                      state.outputPath != null) ...[
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => onOpenResult(state.outputPath!),
                      child: const Text('Open PDF'),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
