import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import '../models/match.dart';

/// Schedules browser notifications 5 minutes before a match kicks off.
/// Timers live only while the page is open (web Notification API).
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

  /// Toggles the reminder for [m].
  /// Returns true if the reminder is now active, false otherwise.
  static Future<bool> toggleReminder(Match m) async {
    // Already scheduled → cancel
    final existing = _scheduled.remove(m.id);
    if (existing != null) {
      existing.cancel();
      return false;
    }

    if (!await _ensurePermission()) return false;

    final fireAt = m.startTime.subtract(_leadTime);
    final wait = fireAt.difference(DateTime.now());
    if (wait.isNegative) {
      // Less than 5 minutes to kickoff — notify immediately
      _show(m);
      return false;
    }

    _scheduled[m.id] = Timer(wait, () {
      _scheduled.remove(m.id);
      _show(m);
    });
    return true;
  }

  static void _show(Match m) {
    try {
      html.Notification(
        '⚽ ${m.homeTeam} × ${m.awayTeam}',
        body: 'المباراة تبدأ خلال 5 دقائق — ${m.tournament}',
        icon: 'icons/Icon-192.png',
      );
    } catch (_) {}
  }
}
