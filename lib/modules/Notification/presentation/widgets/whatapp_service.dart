import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  static Future<void> sendMessage(String phone, String message) async {
    final url = "https://wa.me/$phone?text=${Uri.encodeComponent(message)}";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }
}
