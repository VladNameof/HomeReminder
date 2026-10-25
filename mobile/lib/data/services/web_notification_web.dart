// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:js' as js;

void showWebNotification(String title, String body) {
  try {
    js.context.callMethod('triggerHomeReminderWebPush', [title, body]);
  } catch (_) {}
}
