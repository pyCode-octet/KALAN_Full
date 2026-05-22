/// Bloque les popups de célébration pendant les écrans immersifs (quiz, etc.).
class CelebrationGate {
  static int _depth = 0;

  static bool get isSuppressed => _depth > 0;

  static void enter() => _depth++;

  static void exit() {
    if (_depth > 0) _depth--;
  }
}
