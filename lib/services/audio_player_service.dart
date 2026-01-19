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
      // Validate input type
      if (isPlay is! bool) {
        log("ERROR: playSound called with non-bool value: $isPlay (type: ${isPlay.runtimeType})");
        return;
      }
      
      if (isPlay) {
        final ringtoneUrl = Preferences.getString(Preferences.orderRingtone);
        log("PlaySound :: 11 :: $isPlay :: $ringtoneUrl");
        if (ringtoneUrl.isNotEmpty && _audioPlayer.state != PlayerState.playing) {
          await _audioPlayer.setSource(UrlSource(ringtoneUrl));
          await _audioPlayer.setReleaseMode(ReleaseMode.loop);
          await _audioPlayer.resume();
        }
      } else {
        log("PlaySound :: 22 :: $isPlay :: ${Preferences.getString(Preferences.orderRingtone)}");
        if (_audioPlayer.state != PlayerState.stopped) {
          await _audioPlayer.stop();
        }
      }
    } catch (e, stackTrace) {
      log("Error in playSound: $e");
      log("Stack trace: $stackTrace");
      print("Error in playSound: $e");
    }
  }
}
