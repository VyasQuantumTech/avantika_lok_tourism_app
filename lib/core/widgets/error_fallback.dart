import 'package:flutter/material.dart';

// Flutter still reports exceptions through its normal logging/error handler.
// Only the user-visible fallback changes; stack traces never replace the UI.
void installAppErrorFallback() {
  ErrorWidget.builder = (_) => const AppErrorFallback();
}

class AppErrorFallback extends StatelessWidget {
  const AppErrorFallback({super.key});
  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFFF6F8FC),
        padding: const EdgeInsets.all(12),
        alignment: Alignment.center,
        child: const Text(
            'Unable to display this content. Please reopen the screen and try again.',
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF334155), fontSize: 14)),
      );
}
