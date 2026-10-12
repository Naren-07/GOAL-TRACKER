import 'package:url_launcher/url_launcher.dart';

class WhatsAppShareService {
  final Future<bool> Function(Uri url, {LaunchMode mode})? launcher;

  WhatsAppShareService({this.launcher});

  String cleanPhoneNumber(String phone) {
    return phone.replaceAll(RegExp(r'[^0-9]'), '');
  }

  String buildVerificationUrl({
    required String proofId,
    required String tokenNonce,
    String baseUrl = 'https://growthstreak.app',
  }) {
    return '$baseUrl/verify/$proofId?token=$tokenNonce';
  }

  String buildMessageText({
    required String friendName,
    required String studentName,
    required int streak,
    required String date,
    required String verificationUrl,
  }) {
    return 'Hey $friendName! 🏋️‍♂️ Here is $studentName\'s gym proof for today ($date).\n'
        'Tap here to review & approve: $verificationUrl\n'
        '(Keep their ${streak}d streak alive!)';
  }

  Uri buildWhatsAppUri({
    required String phone,
    required String friendName,
    required String studentName,
    required int streak,
    required String date,
    required String proofId,
    required String tokenNonce,
    String baseUrl = 'https://growthstreak.app',
  }) {
    final cleanPhone = cleanPhoneNumber(phone);
    final verificationUrl = buildVerificationUrl(
      proofId: proofId,
      tokenNonce: tokenNonce,
      baseUrl: baseUrl,
    );
    final message = buildMessageText(
      friendName: friendName,
      studentName: studentName,
      streak: streak,
      date: date,
      verificationUrl: verificationUrl,
    );

    return Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}');
  }

  Future<bool> launchWhatsApp({
    required String phone,
    required String friendName,
    required String studentName,
    required int streak,
    required String date,
    required String proofId,
    required String tokenNonce,
    String baseUrl = 'https://growthstreak.app',
  }) async {
    final uri = buildWhatsAppUri(
      phone: phone,
      friendName: friendName,
      studentName: studentName,
      streak: streak,
      date: date,
      proofId: proofId,
      tokenNonce: tokenNonce,
      baseUrl: baseUrl,
    );

    final customLauncher = launcher;
    if (customLauncher != null) {
      return await customLauncher(uri, mode: LaunchMode.externalApplication);
    }

    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
