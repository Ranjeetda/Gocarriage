import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';

class AudioProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();

  Future<void> play() async {
    await _player.stop();
    await _player.play(AssetSource('sounds/notification.mp3'));
  }

  Future<void> stop() async {
    await _player.stop();
  }
}