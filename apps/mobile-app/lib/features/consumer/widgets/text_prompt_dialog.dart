import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';

/// A dialog asking for a short text (a reason or a note). Owns its text
/// controller, so it is only disposed after the closing animation; returns
/// the text, or null when cancelled.
class TextPromptDialog extends StatefulWidget {
  const TextPromptDialog({
    required this.title,
    required this.hint,
    required this.confirmLabel,
    required this.cancelLabel,
    this.header,
    this.initialText = '',
    this.minLength = 0,
    this.tooShortMessage,
    this.destructive = false,
    this.fieldKey,
    this.confirmKey,
    super.key,
  });

  final String title;
  final String hint;
  final String confirmLabel;
  final String cancelLabel;

  /// Extra content above the text box (e.g. a date/time picker).
  final Widget? header;

  /// Text already in the box when the dialog opens (e.g. when it is shown again).
  final String initialText;
  final int minLength;
  final String? tooShortMessage;
  final bool destructive;
  final Key? fieldKey;
  final Key? confirmKey;

  @override
  State<TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<TextPromptDialog> {
  late final TextEditingController _text = TextEditingController(text: widget.initialText);
  final GlobalKey<FormState> _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (widget.header != null) ...<Widget>[widget.header!, const SizedBox(height: AppSpacing.md)],
            TextFormField(
              key: widget.fieldKey,
              controller: _text,
              maxLength: 300,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(hintText: widget.hint),
              validator: (String? v) =>
                  (v?.trim().length ?? 0) < widget.minLength ? widget.tooShortMessage : null,
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.pop(context), child: Text(widget.cancelLabel)),
        FilledButton(
          key: widget.confirmKey,
          style: widget.destructive ? FilledButton.styleFrom(backgroundColor: AppColors.error) : null,
          onPressed: () {
            if (_form.currentState?.validate() ?? false) Navigator.pop(context, _text.text);
          },
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
