import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/task_source.dart';
import '../providers/speech_provider.dart';
import '../providers/task_matrix_provider.dart';

class VoiceInputSheet extends ConsumerStatefulWidget {
  const VoiceInputSheet({super.key});

  @override
  ConsumerState<VoiceInputSheet> createState() => _VoiceInputSheetState();
}

class _VoiceInputSheetState extends ConsumerState<VoiceInputSheet> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final speechState = ref.watch(speechProvider);

    if (speechState.recognizedWords.isNotEmpty &&
        speechState.recognizedWords != _textController.text) {
      _textController.text = speechState.recognizedWords;
    }

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Voice Task Input',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Speak naturally. Gemini will classify and schedule the task.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          // Pulsing mic button
          GestureDetector(
            onTap: () async {
              if (speechState.isListening) {
                await ref.read(speechProvider.notifier).stopListening();
              } else {
                await ref.read(speechProvider.notifier).startListening();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: speechState.isListening ? Colors.redAccent : AppColors.voicePurple,
                boxShadow: speechState.isListening
                    ? [
                        BoxShadow(
                          color: Colors.redAccent.withAlpha(120),
                          blurRadius: 20,
                          spreadRadius: 4,
                        )
                      ]
                    : [],
              ),
              child: Icon(
                speechState.isListening ? Icons.stop : Icons.mic,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            speechState.isListening ? 'Listening...' : 'Tap mic to speak',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: speechState.isListening ? Colors.redAccent : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _textController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Transcribed speech will appear here...',
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (speechState.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              speechState.errorMessage!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(speechProvider.notifier).reset();
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.voicePurple,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Analyze'),
                  onPressed: _textController.text.trim().isEmpty
                      ? null
                      : () {
                          final text = _textController.text.trim();
                          ref.read(speechProvider.notifier).reset();
                          Navigator.pop(context);
                          ref.read(taskMatrixProvider.notifier).processInputContent(
                                content: text,
                                source: TaskSource.voiceInput,
                              );
                        },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
