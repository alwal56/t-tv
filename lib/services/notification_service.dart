import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import '../models/match.dart';

enum ReminderResult {
  scheduled,   // تم الضبط بنجاح
  firedNow,    // المباراة قريبة جداً → نُبّه فوراً
  canceled,    // أُلغي التنبيه
  denied,      // المتصفح رفض الإشعارات
  unsupported, // المتصفح لا يدعم الإشعارات
}

/// تنبيهات المتصفح قبل المباراة بـ5 دقائق.
/// تعمل ما دامت صفحة الموقع مفتوحة (Web Notification API).
class NotificationService {
  static const _leadTime = Duration(minutes: 5);
  static final _scheduled = <int, Timer>{};

  static bool get supported => html.Notification.supported;

  static bool isScheduled(int matchId) => _scheduled.containsKey(matchId);

  static Future<bool> _ensurePermission() async {
    if (!html.Notification.supported) return false;
    if (html.Notification.permission == 'granted') return true;
    if (html.Notification.permission == 'denied') return false;
    final perm = await html.Notification.requestPermission();
    return perm == 'granted';
  }

  /// يبدّل التنبيه لمباراة [m].
  static Future<ReminderResult> toggleReminder(Match m) async {
    if (!html.Notification.supported) return ReminderResult.unsupported;

    // مضبوط مسبقاً → إلغاء
    final existing = _scheduled.remove(m.id);
    if (existing != null) {
      existing.cancel();
      return ReminderResult.canceled;
    }

    final ok = await _ensurePermission();
    if (!ok) return ReminderResult.denied;

    final fireAt = m.startTime.subtract(_leadTime);
    final wait = fireAt.difference(DateTime.now());

    if (wait.isNegative) {
      // أقل من 5 دقائق على البداية → نبّه الآن
      _show(
        '⚽ ${m.homeTeam} × ${m.awayTeam}',
        'المباراة على وشك أن تبدأ — ${m.tournament}',
      );
      return ReminderResult.firedNow;
    }

    // إشعار تأكيد فوري ليتأكد المستخدم أن التنبيهات تعمل
    _show(
      '🔔 تم ضبط تنبيه',
      'سننبّهك قبل ${m.homeTeam} × ${m.awayTeam} بـ5 دقائق',
    );

    _scheduled[m.id] = Timer(wait, () {
      _scheduled.remove(m.id);
      _show(
        '⚽ ${m.homeTeam} × ${m.awayTeam}',
        'المباراة تبدأ خلال 5 دقائق — ${m.tournament}',
      );
    });
    return ReminderResult.scheduled;
  }

  static void _show(String title, String body) {
    try {
      html.Notification(title, body: body, icon: 'icons/Icon-192.png');
    } catch (_) {}
  }
}
