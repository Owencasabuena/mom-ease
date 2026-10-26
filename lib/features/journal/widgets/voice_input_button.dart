import 'package:flutter/material.dart';
import '../services/speech_service.dart';

/// Ergonomic, accessible microphone button for speech-to-text journaling.
///
/// Designed with large touch targets and high-contrast state labels
/// for tired mothers holding a baby with one hand.
class VoiceInputButton extends StatelessWidget {
  final SpeechService speechService;
  final VoidCallback onPressed;

  const VoiceInputButton({
    super.key,
    required this.speechService,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = speechService.status;
    final isListening = status == SpeechStatus.listening;
    final isProcessing = status == SpeechStatus.processing;

    Color buttonColor;
    Color iconColor;
    IconData icon;

    switch (status) {
      case SpeechStatus.listening:
        buttonColor = theme.colorScheme.error;
        iconColor = Colors.white;
        icon = Icons.mic_rounded;
        break;
      case SpeechStatus.processing:
        buttonColor = theme.colorScheme.tertiary;
        iconColor = Colors.white;
        icon = Icons.hourglass_top_rounded;
        break;
      case SpeechStatus.permissionDenied:
        buttonColor = theme.colorScheme.surfaceContainerHighest;
        iconColor = theme.colorScheme.error;
        icon = Icons.mic_off_rounded;
        break;
      case SpeechStatus.unavailable:
        buttonColor = theme.colorScheme.surfaceContainerHighest;
        iconColor = theme.colorScheme.onSurfaceVariant;
        icon = Icons.mic_none_rounded;
        break;
      case SpeechStatus.idle:
        buttonColor = theme.colorScheme.primaryContainer;
        iconColor = theme.colorScheme.primary;
        icon = Icons.mic_rounded;
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: speechService.statusMessage,
          button: true,
          child: Material(
            color: buttonColor,
            shape: const CircleBorder(),
            elevation: isListening ? 4 : 0,
            child: InkWell(
              onTap: isProcessing ? null : onPressed,
              customBorder: const CircleBorder(),
              child: Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                child: isProcessing
                    ? const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        icon,
                        size: 32,
                        color: iconColor,
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            isListening
                ? 'Listening... Tap to stop'
                : speechService.statusMessage,
            key: ValueKey(speechService.statusMessage),
            style: theme.textTheme.labelMedium?.copyWith(
              color: isListening
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: isListening ? FontWeight.bold : FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
