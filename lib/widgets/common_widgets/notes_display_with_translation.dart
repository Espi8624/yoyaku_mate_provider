import 'package:flutter/material.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/services/translation_service.dart';

class NotesDisplayWithTranslation extends StatefulWidget {
  final String notes;

  const NotesDisplayWithTranslation({
    super.key,
    required this.notes,
  });

  @override
  State<NotesDisplayWithTranslation> createState() =>
      _NotesDisplayWithTranslationState();
}

class _NotesDisplayWithTranslationState
    extends State<NotesDisplayWithTranslation> {
  bool _isTranslated = false;
  bool _isLoading = false;
  String? _translatedText;

  Future<void> _translateNotes() async {
    if (_translatedText != null) {
      setState(() {
        _isTranslated = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await TranslationService().translate(widget.notes);

    if (!mounted) return;

    setState(() {
      _translatedText = result;
      _isLoading = false;
      _isTranslated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.notes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _isTranslated && _translatedText != null
                    ? _translatedText!
                    : widget.notes,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            if (!_isTranslated)
              IconButton(
                onPressed: _isLoading ? null : _translateNotes,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.accentPrimary,
                        ),
                      )
                    : const Icon(Icons.translate,
                        color: AppColors.accentPrimary),
                tooltip: '翻訳する',
              )
            else
              IconButton(
                onPressed: () {
                  setState(() {
                    _isTranslated = false;
                  });
                },
                icon: const Icon(Icons.undo, color: Colors.grey),
                tooltip: '原文に戻す',
              ),
          ],
        ),
        if (_isTranslated)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              '原文: ${widget.notes}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
      ],
    );
  }
}
