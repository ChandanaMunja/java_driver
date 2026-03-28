import 'dart:developer';

import 'package:audioplayers/audioplayers.dart';
import 'package:jippydriver_driver/utils/preferences.dart';

class AudioPlayerService {
  static late AudioPlayer _audioPlayer;

  static initAudio() async {
    _audioPlayer = AudioPlayer(playerId: "playerId");
  }

  static Future<void> playSound(bool isPlay) async {
    try {
      if (isPlay) {
        final ringtoneUrl = Preferences.getString(Preferences.orderRingtone);
        log("PlaySound :: START :: $ringtoneUrl");

        if (ringtoneUrl.isNotEmpty) {
          // Always reset before playing (IMPORTANT)
          await _audioPlayer.stop();

          await _audioPlayer.setSource(UrlSource(ringtoneUrl));
          await _audioPlayer.setReleaseMode(ReleaseMode.loop);
          await _audioPlayer.play(UrlSource(ringtoneUrl)); // ✅ use play instead of resume
        }
      } else {
        log("PlaySound :: STOP");

        // ✅ Always stop (no condition)
        await _audioPlayer.stop();
      }
    } catch (e, stackTrace) {
      log("Error in playSound: $e");
      log("Stack trace: $stackTrace");
    }
  }
}
