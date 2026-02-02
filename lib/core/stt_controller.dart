import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:sound_mode/sound_mode.dart';
import 'package:sound_mode/utils/ringer_mode_statuses.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class SttPttController {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _ready = false;
  bool _isListening = false;

  String _lastPartial = '';
  String _lastFinal = '';
  Completer<String>? _finalCompleter;
  Future<void>? _startOp;

  Future<bool> _requestPermission() async {
    var status = await Permission.microphone.status;
    if (status.isDenied) {
      status = await Permission.microphone.request();
    }
    return status.isGranted;
  }

  Future<void> init() async {
    debugPrint("STT: Initializing...");

    // Explicitly check permission first
    final hasPermission = await _requestPermission();
    if (!hasPermission) {
      debugPrint("STT: Microphone permission denied.");
      _ready = false;
      return;
    }

    try {
      _ready = await _speech.initialize(
        onStatus: (s) {
          debugPrint("STT Status: $s");
          if (s == 'listening') _isListening = true;
          if (s == 'notListening' || s == 'done') _isListening = false;
        },
        onError: (e) {
          debugPrint("STT Error: ${e.errorMsg} (${e.permanent})");
          _isListening = false;
        },
      );
    } catch (e) {
      debugPrint("STT Initialization Exception: $e");
      _ready = false;
    }
    debugPrint("STT Ready: $_ready");
  }

  Future<void> _playFeedback({bool isRelease = false}) async {
    try {
      RingerModeStatus ringerStatus = await SoundMode.ringerModeStatus;

      if (ringerStatus == RingerModeStatus.silent ||
          ringerStatus == RingerModeStatus.vibrate) {
        // Haptic only
        if (await Vibration.hasVibrator() == true) {
          if (isRelease) {
            Vibration.vibrate(duration: 40); // Shorter for release
          } else {
            Vibration.vibrate(duration: 70); // Concise for start
          }
        } else {
          isRelease
              ? HapticFeedback.lightImpact()
              : HapticFeedback.mediumImpact();
        }
        debugPrint("STT Feedback: Silent/Vibrate mode - Haptic triggered.");
      } else {
        // Concise Sound feedback
        // SystemSound.click is much more concise than a long mp3 ding
        await SystemSound.play(SystemSoundType.click);
        debugPrint("STT Feedback: Sound mode - System click played.");
      }
    } catch (e) {
      debugPrint("STT Feedback Error: $e");
      HapticFeedback.lightImpact();
    }
  }

  bool get isReady => _ready;
  bool get isListening => _isListening;

  // Debug tracking
  final List<Map<String, dynamic>> _partialHistory = [];
  int _partialCount = 0;

  Future<void> start({String localeId = 'ko-KR'}) async {
    // Play feedback first to signal user
    await _playFeedback();

    _partialHistory.clear();
    _partialCount = 0;
    _startOp = _startInternal(localeId: localeId);
    await _startOp;
  }

  Future<void> _startInternal({String localeId = 'ko-KR'}) async {
    if (!_ready) {
      debugPrint("STT: Start called but not ready. Attempting re-init...");
      await init();
      if (!_ready) {
        debugPrint("STT: Re-init failed. Cannot start.");
        return;
      }
    }

    debugPrint("STT: Listening starting (locale: $localeId)...");
    _lastPartial = '';
    _lastFinal = '';
    _finalCompleter = Completer<String>();

    try {
      await _speech.listen(
        localeId: localeId,
        partialResults: true,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        // Try to preserve Korean numerals by disabling auto-formatting
        onDevice: false, // Use cloud recognition for better accuracy
        onResult: (r) {
          var text = r.recognizedWords.trim();

          // 🔍 DETAILED PARTIAL TRACKING
          if (!r.finalResult) {
            _partialCount++;
            _partialHistory.add({
              'index': _partialCount,
              'text': text,
              'length': text.length,
              'timestamp': DateTime.now(),
            });
            debugPrint(
              "STT Partial #$_partialCount: \"$text\" (${text.length} chars)",
            );
          }

          // 🎯 SAFE ALTERNATES CHECK: Prefer longer results BUT prevent "Unit Inflation"
          if (r.finalResult && r.alternates.isNotEmpty) {
            for (final alt in r.alternates) {
              final altText = alt.recognizedWords;
              // 1. Must be longer to be worth considering
              if (altText.length > text.length) {
                // 2. Safety Check: Don't accept if it adds a Major Unit (만, 억, 조) when Primary didn't have one.
                // This prevents "3980" -> "3980만" inflation errors.
                bool primaryHasUnit = _hasMajorUnit(text);
                bool altHasUnit = _hasMajorUnit(altText);

                if (primaryHasUnit || !altHasUnit) {
                  debugPrint(
                    "STT: ✅ Accepted longer alternate: \"$altText\" (Primary: \"$text\")",
                  );
                  text = altText;
                } else {
                  debugPrint(
                    "STT: ⚠️ Rejected inflated alternate: \"$altText\" (Primary: \"$text\" has no unit)",
                  );
                }
              }
            }
          }

          debugPrint("STT Result: \"$text\" (final: ${r.finalResult})");
          if (text.isEmpty) return;

          _lastPartial = text;
          if (r.finalResult) {
            _lastFinal = text;

            // 🎯 CRITICAL ANALYSIS: Final vs Longest Partial
            if (_partialHistory.isNotEmpty) {
              final longest = _partialHistory.reduce(
                (a, b) => (a['length'] as int) > (b['length'] as int) ? a : b,
              );
              debugPrint("┌─────────────────────────────────");
              debugPrint("│ 🔍 STT ANALYSIS:");
              debugPrint("│ Total partials: ${_partialHistory.length}");
              debugPrint(
                "│ Longest partial: \"${longest['text']}\" (${longest['length']} chars)",
              );
              debugPrint("│ Final result: \"$text\" (${text.length} chars)");
              if ((longest['length'] as int) > text.length) {
                debugPrint(
                  "│ ⚠️ WARNING: Final is SHORTER than longest partial!",
                );
                debugPrint(
                  "│ Lost ${(longest['length'] as int) - text.length} characters!",
                );
              } else if (longest['text'] != text) {
                debugPrint("│ ℹ️ Final differs from longest partial");
              } else {
                debugPrint("│ ✅ Final matches longest partial");
              }
              debugPrint("└─────────────────────────────────");
            }

            if (!(_finalCompleter?.isCompleted ?? true)) {
              _finalCompleter!.complete(_lastFinal);
            }
          }
        },
      );
    } catch (e) {
      debugPrint("STT Listen Error: $e");
      _isListening = false;
    }
  }

  /// 손을 뺐을 때 호출: stop 후 final을 짧게 기다림
  /// Google STT가 반복 숫자를 필터링하는 문제 해결: partial 중 가장 긴 결과 우선 사용
  Future<String> stopAndGetFinal({
    Duration grace = const Duration(milliseconds: 500),
    Duration wait = const Duration(milliseconds: 3000),
  }) async {
    if (!_ready) return '';

    // Play feedback for release/stop as well
    await _playFeedback(isRelease: true);

    // 만약 start가 아직 진행 중이라면 기다려줌
    if (_startOp != null) {
      debugPrint("STT: Waiting for start operation to complete...");
      await _startOp;
    }

    // 버튼을 뗐어도 아주 짧은 시간 더 들음 (말이 안 잘리게)
    debugPrint("STT: PTT Released. Grace period (500ms) for trailing audio...");
    await Future.delayed(grace);

    debugPrint("STT: Stopping engine...");
    await _speech.stop();
    _isListening = false;

    // 1) 이미 final이 있으면 partial과 비교
    if (_lastFinal.isNotEmpty) {
      // Google STT 반복 필터 우회: partial이 final보다 길면 partial 사용
      if (_lastPartial.length > _lastFinal.length) {
        debugPrint(
          "STT: ⚠️ Final result shorter than partial. Using partial instead!",
        );
        debugPrint("    Final: \"$_lastFinal\" (${_lastFinal.length} chars)");
        debugPrint(
          "    Partial: \"$_lastPartial\" (${_lastPartial.length} chars)",
        );
        return _lastPartial;
      }
      debugPrint("STT: Final result already exists: \"$_lastFinal\"");
      return _lastFinal;
    }

    // 2) final 이벤트가 늦게 도착할 수 있으므로 wait 동안 대기
    try {
      final c = _finalCompleter;
      if (c == null) {
        return _lastPartial;
      }
      debugPrint("STT: Waiting up to 3s for final result event...");
      final res = await c.future.timeout(wait);

      // Final을 받았어도 partial과 비교
      if (_lastPartial.length > res.length) {
        debugPrint(
          "STT: ⚠️ Final result shorter than partial. Using partial instead!",
        );
        debugPrint("    Final: \"$res\" (${res.length} chars)");
        debugPrint(
          "    Partial: \"$_lastPartial\" (${_lastPartial.length} chars)",
        );
        return _lastPartial;
      }

      debugPrint("STT: Got final result via future: \"$res\"");
      return res;
    } catch (_) {
      debugPrint(
        "STT: Timeout or no final result. Returning last partial: \"$_lastPartial\"",
      );
      return _lastFinal.isNotEmpty ? _lastFinal : _lastPartial;
    }
  }

  bool _hasMajorUnit(String text) {
    return text.contains(RegExp(r'[만억조]'));
  }
}
