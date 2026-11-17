import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:flutter_tts/flutter_tts.dart';

/// Read-aloud helper for early readers. Fails quietly when no speech engine
/// is available (for example in unit tests).
class Speech extends ChangeNotifier {
  Speech._();
  static final instance = Speech._();

  FlutterTts? _tts;
  bool _ready = false;
  bool _missing = false;

  /// When on, results and prompts are read out loud on their own.
  bool autoRead = true;

  void toggleAutoRead() {
    autoRead = !autoRead;
    if (!autoRead) stop();
    notifyListeners();
  }

  Future<bool> _init() async {
    if (_ready) return true;
    if (_missing) return false;
    try {
      final tts = FlutterTts();
      Future<void> opt(Future<dynamic> Function() f) async {
        try {
          await f();
        } on MissingPluginException {
          rethrow;
        } catch (e) {
          debugPrint('Speech setup skipped: $e');
        }
      }

      await opt(() => tts.setSharedInstance(true));
      await opt(() => tts.setIosAudioCategory(
              IosTextToSpeechAudioCategory.playback,
              [
                IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
                IosTextToSpeechAudioCategoryOptions.mixWithOthers,
              ],
              IosTextToSpeechAudioMode.defaultMode));
      await opt(() => tts.setVolume(1.0));
      await opt(() => tts.setLanguage('en-US'));
      await opt(() => tts.setPitch(1.1));
      await opt(() => tts.awaitSpeakCompletion(true));
      _tts = tts;
      _ready = true;
    } on MissingPluginException {
      _missing = true;
      debugPrint('Speech unavailable: plugin not linked. Stop and rebuild the app.');
    } catch (e) {
      debugPrint('Speech init failed: $e');
    }
    return _ready;
  }

  Future<void> speak(String text, {double rate = 0.42}) async {
    if (!await _init()) return;
    try {
      await _tts!.stop();
      await _tts!.setSpeechRate(rate);
      await _tts!.speak(text);
    } on MissingPluginException {
      _ready = false;
      _missing = true;
      debugPrint('Speech unavailable: plugin not linked. Stop and rebuild the app.');
    } catch (e) {
      debugPrint('Speech failed: $e');
    }
  }

  /// Reads only when "Read to me" is on.
  Future<void> auto(String text) async {
    if (autoRead) await speak(text);
  }


  Future<void> stop() async {
    if (!_ready) return;
    try {
      await _tts!.stop();
    } catch (_) {}
  }
}
