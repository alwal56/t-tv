// Native implementation — Android / Windows فقط
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// Wrapper حول VideoController يُضيف dispose() فارغ للتوافق مع الـ stub
class NativeVideoController {
  final VideoController _ctrl;
  NativeVideoController(dynamic player) : _ctrl = VideoController(player as Player);
  VideoController get controller => _ctrl;
  void dispose() {} // VideoController لا تحتاج dispose منفصل — الـ Player يتكفّل
}

class NativeVideo extends StatelessWidget {
  final NativeVideoController controller;
  final BoxFit fit;
  const NativeVideo({super.key, required this.controller, this.fit = BoxFit.contain});

  @override
  Widget build(BuildContext context) {
    return Video(controller: controller.controller, fit: fit);
  }
}

NativeVideoController createVideoController(dynamic player) {
  return NativeVideoController(player);
}
