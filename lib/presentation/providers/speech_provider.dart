import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/voice_datasource.dart';

class SpeechState {
  final bool isListening;
  final String recognizedWords;
  final bool isFinal;
  final String? errorMessage;

  const SpeechState({
    this.isListening = false,
    this.recognizedWords = '',
    this.isFinal = false,
    this.errorMessage,
  });

  SpeechState copyWith({
    bool? isListening,
    String? recognizedWords,
    bool? isFinal,
    String? errorMessage,
  }) {
    return SpeechState(
      isListening: isListening ?? this.isListening,
      recognizedWords: recognizedWords ?? this.recognizedWords,
      isFinal: isFinal ?? this.isFinal,
      errorMessage: errorMessage,
    );
  }
}

class SpeechNotifier extends Notifier<SpeechState> {
  final VoiceDatasource _datasource = VoiceDatasource();

  @override
  SpeechState build() {
    return const SpeechState();
  }

  Future<void> startListening() async {
    state = const SpeechState(isListening: true, recognizedWords: '');
    try {
      await _datasource.startListening(
        onResult: (text, isFinal) {
          state = state.copyWith(
            recognizedWords: text,
            isFinal: isFinal,
            isListening: !isFinal,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        isListening: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> stopListening() async {
    await _datasource.stopListening();
    state = state.copyWith(isListening: false);
  }

  Future<void> cancelListening() async {
    await _datasource.cancelListening();
    state = const SpeechState(isListening: false);
  }

  void reset() {
    state = const SpeechState();
  }
}

final speechProvider =
    NotifierProvider<SpeechNotifier, SpeechState>(SpeechNotifier.new);
