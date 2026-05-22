// Web implementation — عنصر HTML <video> مدمج في Flutter عبر HtmlElementView
// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';
import '../web/web_player.dart';

class NativeVideoController {
  final html.VideoElement _video;
  final String _viewId;
  final dynamic _player;

  NativeVideoController(dynamic player)
      : _video = html.VideoElement(),
        _viewId = 'ttv-video-${DateTime.now().millisecondsSinceEpoch}',
        _player = player {
    // ضبط عنصر الـ video
    _video
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.background = '#000000'
      ..style.objectFit = 'contain'
      ..setAttribute('playsinline', 'true') // iOS: تشغيل داخل الصفحة وليس fullscreen
      ..setAttribute('webkit-playsinline', 'true') // iOS القديمة
      ..controls = false
      ..autoplay = false;

    // تسجيل factory للـ HtmlElementView
    ui.platformViewRegistry.registerViewFactory(_viewId, (_) => _video);

    // ربط callbacks مع عنصر الـ video
    if (player is WebVideoPlayer) {
      // تشغيل رابط جديد
      player.onPlay = (String url) => _startPlayback(url);

      // إيقاف/تشغيل
      player.onTogglePlay = () {
        if (_video.paused) {
          _video.play().catchError((_) {});
        } else {
          _video.pause();
        }
      };

      // الصوت (0.0 - 100.0 → 0.0 - 1.0)
      player.onSetVolume = (double volume) {
        _video.volume = (volume / 100.0).clamp(0.0, 1.0);
      };

      // إذا كان هناك رابط محفوظ مسبقاً، ابدأ التشغيل فوراً
      final existingUrl = player.url;
      if (existingUrl != null && existingUrl.isNotEmpty) {
        _startPlayback(existingUrl);
      }
    }
  }

  /// يبدأ التشغيل — muted أولاً (iOS Safari يسمح بـ muted autoplay دائماً)
  /// ثم يرفع الصوت فوراً بعد بدء التشغيل
  void _startPlayback(String url) {
    _video.src = url;
    _video.muted = true; // مطلوب لـ autoplay على iOS Safari
    _video.load();
    _video.play().then((_) {
      // رفع الصوت بعد ما يبدأ التشغيل فعلياً
      _video.muted = false;
    }).catchError((_) {
      // حتى muted autoplay فشل — المستخدم يضغط ▶ يدوياً
      _video.muted = false;
    });
  }

  String get viewId => _viewId;

  void dispose() {
    // تنظيف callbacks
    if (_player is WebVideoPlayer) {
      _player.onPlay = null;
      _player.onTogglePlay = null;
      _player.onSetVolume = null;
    }
    _video.pause();
    _video.src = '';
  }
}

class NativeVideo extends StatelessWidget {
  final NativeVideoController controller;
  final BoxFit fit;
  const NativeVideo(
      {super.key, required this.controller, this.fit = BoxFit.contain});

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: controller.viewId);
  }
}

NativeVideoController createVideoController(dynamic player) {
  return NativeVideoController(player);
}
