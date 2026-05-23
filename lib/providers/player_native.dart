// Native implementation — Android / Windows فقط
import 'package:media_kit/media_kit.dart';

dynamic createNativePlayer() {
  return Player();
}

void setupPlayerListeners(
  dynamic player,
  void Function(bool) onPlaying,
  void Function(bool) onBuffering,
  void Function(String) onError,
) {
  final p = player as Player;
  p.stream.playing.listen(onPlaying);
  p.stream.buffering.listen(onBuffering);
  p.stream.error.listen(onError);
}

Future<void> openMedia(dynamic player, String url) async {
  final p = player as Player;
  await p.open(Media(url));
}

Future<void> playerTogglePlay(dynamic player) async {
  final p = player as Player;
  await p.playOrPause();
}

Future<void> playerSetVolume(dynamic player, double volume) async {
  final p = player as Player;
  await p.setVolume(volume);
}

void disposePlayer(dynamic player) {
  final p = player as Player;
  p.dispose();
}
