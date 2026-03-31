import 'dart:developer';

import 'package:audioplayers/audioplayers.dart';
import 'package:jippydriver_driver/constant/constant.dart';
import 'package:jippydriver_driver/utils/preferences.dart';

/// Single [AudioPlayer] for order URL ringtone in the **main isolate** only.
/// Background FCM must not use this (separate isolate → Accept/Reject cannot stop it).
class AudioPlayerService {
  static AudioPlayer? _audioPlayer;

  /// Stops and replaces any existing player so a new session cannot leave audio running.
  static Future<void> initAudio() async {
    await _disposePlayer();
    _audioPlayer = AudioPlayer(playerId: 'order_ringtone_url');
  }

  static Future<void> _disposePlayer() async {
    final p = _audioPlayer;
    _audioPlayer = null;
    if (p == null) return;
    try {
      await p.stop();
      await p.dispose();
    } catch (e, st) {
      log('AudioPlayerService dispose: $e\n$st');
    }
  }

  static Future<void> playSound(bool isPlay) async {
    try {
      if (isPlay) {
        if (_audioPlayer == null) await initAudio();
        final player = _audioPlayer;
        if (player == null) return;

        var ringtoneUrl = Preferences.getString(Preferences.orderRingtone).trim();
        if (ringtoneUrl.isEmpty) ringtoneUrl = Constant.orderRingtoneUrl.trim();
        log('PlaySound :: START :: $ringtoneUrl');

        if (ringtoneUrl.isNotEmpty) {
          await player.stop();
          await player.setReleaseMode(ReleaseMode.loop);
          await player.play(UrlSource(ringtoneUrl));
        }
      } else {
        log('PlaySound :: STOP');
        final player = _audioPlayer;
        if (player == null) return;
        await player.stop();
        await player.setReleaseMode(ReleaseMode.stop);
      }
    } catch (e, stackTrace) {
      log('Error in playSound: $e');
      log('Stack trace: $stackTrace');
    }
  }
}
