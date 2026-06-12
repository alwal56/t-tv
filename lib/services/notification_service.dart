import 'dart:async';

import '../models/match.dart';
import 'web_interop.dart';

enum ReminderResult {
  scheduled,   // تم الضبط بنجاح
  firedNow,    // المباراة قريبة جداً → نُبّه فوراً
  canceled,    // أُلغي التنبيه
  denied,      // المتصفح رفض الإشعارات
  unsupported, // المنصّة لا تدعم الإشعارات
}

/// تنبيهات قبل المباراة بـ5 دقائق.
/// تعمل ما دامت صفحة الموقع مفتوحة (Web Notification API).
class NotificationService {
  static const _leadTime = Duration(minutes: 5);
  static final _scheduled = <int, Timer>{};

  static bool get supported => WebInterop.notificationsSupported;

  static bool isScheduled(int matchId) => _scheduled.containsKey(matchId);

  static Future<bool> _ensurePermission() =>
      WebInterop.requestNotificationPermission();

  /// يبدّل التنبيه لمباراة [m].
  static Future<ReminderResult> toggleReminder(Match m) async {
    if (!WebInterop.notificationsSupported) return ReminderResult.unsupported;

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
      WebInterop.showNotification(
        '⚽ ${m.homeTeam} × ${m.awayTeam}',
        'المباراة على وشك أن تبدأ — ${m.tournament}',
      );
      return ReminderResult.firedNow;
    }

    // إشعار تأكيد فوري ليتأكد المستخدم أن التنبيهات تعمل
    WebInterop.showNotification(
      '🔔 تم ضبط تنبيه',
      'سننبّهك قبل ${m.homeTeam} × ${m.awayTeam} بـ5 دقائق',
    );

    _scheduled[m.id] = Timer(wait, () {
      _scheduled.remove(m.id);
      WebInterop.showNotification(
        '⚽ ${m.homeTeam} × ${m.awayTeam}',
        'المباراة تبدأ خلال 5 دقائق — ${m.tournament}',
      );
    });
    return ReminderResult.scheduled;
  }
}
