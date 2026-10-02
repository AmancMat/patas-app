// Interface de fallback para plataformas não-web (Android, iOS)
bool isWebNotificationSupported() => false;

String getWebNotificationPermission() => 'unsupported';

Future<String> requestWebNotificationPermission() async => 'unsupported';

void showBrowserNotification({
  required String title,
  required String body,
  String? icon,
}) {}

