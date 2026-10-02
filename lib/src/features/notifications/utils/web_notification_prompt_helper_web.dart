// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

bool isWebNotificationSupported() {
  try {
    return html.Notification.supported;
  } catch (_) {
    return false;
  }
}

String getWebNotificationPermission() {
  try {
    if (!html.Notification.supported) return 'unsupported';
    return html.Notification.permission ?? 'default';
  } catch (_) {
    return 'unsupported';
  }
}

Future<String> requestWebNotificationPermission() async {
  try {
    if (!html.Notification.supported) return 'unsupported';
    final permission = await html.Notification.requestPermission();
    return permission;
  } catch (_) {
    return 'denied';
  }
}

void showBrowserNotification({
  required String title,
  required String body,
  String? icon,
}) {
  try {
    if (!html.Notification.supported) return;
    if (html.Notification.permission == 'granted') {
      html.Notification(
        title,
        body: body,
        icon: icon ?? 'icons/Icon-192.png',
      );
    }
  } catch (_) {}
}

