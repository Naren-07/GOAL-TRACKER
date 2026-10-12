import 'package:flutter_test/flutter_test.dart';
import 'package:growthstreak/features/proofs/domain/whatsapp_share_service.dart';

void main() {
  group('WhatsAppShareService Seam', () {
    late WhatsAppShareService service;

    setUp(() {
      service = WhatsAppShareService();
    });

    test('cleanPhoneNumber sanitizes formatted phone to digits only', () {
      expect(service.cleanPhoneNumber('+91 98765-43210'), '919876543210');
      expect(service.cleanPhoneNumber('+1 (555) 123-4567'), '15551234567');
      expect(service.cleanPhoneNumber('9876543210'), '9876543210');
    });

    test('buildVerificationUrl formats signed URL with proofId and token nonce', () {
      final url = service.buildVerificationUrl(
        proofId: 'proof_12345',
        tokenNonce: 'nonce_abcdef9876543210',
      );

      expect(
        url,
        'https://growthstreak.app/verify/proof_12345?token=nonce_abcdef9876543210',
      );
    });

    test('buildWhatsAppUri creates valid wa.me URI with URL-encoded prefilled text', () {
      final uri = service.buildWhatsAppUri(
        phone: '+919876543210',
        friendName: 'Bob',
        studentName: 'Naren',
        streak: 5,
        date: '2026-10-12',
        proofId: 'proof_12345',
        tokenNonce: 'nonce_abc123',
      );

      expect(uri.scheme, 'https');
      expect(uri.host, 'wa.me');
      expect(uri.path, '/919876543210');
      expect(uri.queryParameters['text'], isNotNull);
      expect(uri.queryParameters['text'], contains('proof_12345'));
      expect(uri.queryParameters['text'], contains('nonce_abc123'));
      expect(uri.queryParameters['text'], contains('5d streak'));
    });
  });
}
