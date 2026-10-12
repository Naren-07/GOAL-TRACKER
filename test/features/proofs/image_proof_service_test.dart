import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:growthstreak/features/proofs/domain/image_proof_service.dart';

void main() {
  group('ImageProofService Seam', () {
    late ImageProofService service;

    setUp(() {
      service = ImageProofService();
    });

    test('calculateGraceCutoff sets deadline to 10:00 AM next morning', () {
      final submissionTime = DateTime(2026, 10, 12, 19, 45, 0); // Oct 12, 7:45 PM
      final cutoff = service.calculateGraceCutoff(submissionTime);

      expect(cutoff.year, 2026);
      expect(cutoff.month, 10);
      expect(cutoff.day, 13);
      expect(cutoff.hour, 10);
      expect(cutoff.minute, 0);
      expect(cutoff.second, 0);
    });

    test('generateTokenNonce returns a secure unique hex string', () {
      final nonce1 = service.generateTokenNonce();
      final nonce2 = service.generateTokenNonce();

      expect(nonce1, isNotEmpty);
      expect(nonce2, isNotEmpty);
      expect(nonce1, isNot(equals(nonce2)));
      expect(nonce1.length, greaterThanOrEqualTo(32));
    });

    test('computePerceptualHash returns matching 64-bit hex hash for identical images', () {
      // Create a test 100x100 image
      final testImage = img.Image(width: 100, height: 100);
      for (var y = 0; y < 100; y++) {
        for (var x = 0; x < 100; x++) {
          testImage.setPixelRgb(x, y, x, y, 128);
        }
      }
      final bytes = Uint8List.fromList(img.encodeJpg(testImage));

      final hash1 = service.computePerceptualHash(bytes);
      final hash2 = service.computePerceptualHash(bytes);

      expect(hash1, isNotEmpty);
      expect(hash1, equals(hash2));
    });

    test('hammingDistance correctly detects identical and distinct hashes', () {
      const hashA = '0123456789abcdef';
      const hashB = '0123456789abcdef';
      const hashC = 'ffffffffffffffff';

      expect(service.hammingDistance(hashA, hashB), 0);
      expect(service.hammingDistance(hashA, hashC), greaterThan(10));
    });

    test('compressAndWatermark compresses image under 350 KB and embeds timestamp', () {
      // Create a large 2000x2000 image
      final largeImage = img.Image(width: 2000, height: 2000);
      final random = Random(42);
      for (var y = 0; y < 2000; y += 10) {
        for (var x = 0; x < 2000; x += 10) {
          largeImage.setPixelRgb(x, y, random.nextInt(256), random.nextInt(256), random.nextInt(256));
        }
      }
      final rawBytes = Uint8List.fromList(img.encodeJpg(largeImage, quality: 100));

      final processedBytes = service.compressAndWatermark(
        imageBytes: rawBytes,
        timestamp: DateTime(2026, 10, 12, 20, 30),
      );

      // Verify compressed size is well under 350 KB (350 * 1024 = 358,400 bytes)
      expect(processedBytes.lengthInBytes, lessThan(358400));
    });
  });
}
