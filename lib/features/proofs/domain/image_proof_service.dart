import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';

class ImageProofService {
  /// Calculates the grace cutoff: 10:00 AM of the morning following the submission
  DateTime calculateGraceCutoff(DateTime submissionTime) {
    final nextDay = submissionTime.add(const Duration(days: 1));
    return DateTime(nextDay.year, nextDay.month, nextDay.day, 10, 0, 0);
  }

  /// Generates a cryptographically secure 32-character hexadecimal token nonce
  String generateTokenNonce() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Computes a 64-bit difference hash (dHash) represented as a 16-character hex string
  String computePerceptualHash(Uint8List imageBytes) {
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) {
      throw ArgumentError('Unable to decode image bytes for perceptual hash');
    }

    // Resize to 9x8 grayscale
    final grayscale = img.grayscale(decoded);
    final resized = img.copyResize(grayscale, width: 9, height: 8);

    final bitBuffer = StringBuffer();
    for (var y = 0; y < 8; y++) {
      for (var x = 0; x < 8; x++) {
        final left = resized.getPixel(x, y).r;
        final right = resized.getPixel(x + 1, y).r;
        bitBuffer.write(left > right ? '1' : '0');
      }
    }

    // Convert 64 bits to 16 hex digits
    final bits = bitBuffer.toString();
    final hexBuffer = StringBuffer();
    for (var i = 0; i < 64; i += 4) {
      final chunk = bits.substring(i, i + 4);
      final value = int.parse(chunk, radix: 2);
      hexBuffer.write(value.toRadixString(16));
    }

    return hexBuffer.toString();
  }

  /// Calculates the Hamming distance between two 16-character hex dHashes
  int hammingDistance(String hash1, String hash2) {
    if (hash1.length != hash2.length) {
      return 64;
    }

    var distance = 0;
    for (var i = 0; i < hash1.length; i++) {
      final val1 = int.tryParse(hash1[i], radix: 16) ?? 0;
      final val2 = int.tryParse(hash2[i], radix: 16) ?? 0;
      var xor = val1 ^ val2;
      while (xor > 0) {
        if ((xor & 1) == 1) distance++;
        xor >>= 1;
      }
    }
    return distance;
  }

  /// Checks if two hashes are perceptually identical (threshold <= 5 bits difference)
  bool isDuplicate(String hash1, String hash2, {int threshold = 5}) {
    return hammingDistance(hash1, hash2) <= threshold;
  }

  /// Resizes image to standard resolution, draws date/time watermark, and compresses JPEG under 350 KB
  Uint8List compressAndWatermark({
    required Uint8List imageBytes,
    required DateTime timestamp,
    int maxDimension = 1280,
    int targetMaxBytes = 358400, // 350 KB
  }) {
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) {
      throw ArgumentError('Unable to decode image bytes for compression');
    }

    // Resize so largest dimension is at most maxDimension
    img.Image resized = decoded;
    if (decoded.width > maxDimension || decoded.height > maxDimension) {
      if (decoded.width >= decoded.height) {
        resized = img.copyResize(decoded, width: maxDimension);
      } else {
        resized = img.copyResize(decoded, height: maxDimension);
      }
    }

    // Add watermark text banner at bottom
    final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(timestamp);
    final watermarkText = '$formattedDate  *  GrowthStreak Verified';

    // Draw a dark semi-transparent banner bar at the bottom
    final bannerHeight = 36;
    final bannerY = resized.height - bannerHeight;
    img.fillRect(
      resized,
      x1: 0,
      y1: bannerY > 0 ? bannerY : 0,
      x2: resized.width,
      y2: resized.height,
      color: img.ColorRgba8(0, 0, 0, 160),
    );

    // Draw watermark text string
    img.drawString(
      resized,
      watermarkText,
      font: img.arial14,
      x: 16,
      y: bannerY + 10 > 0 ? bannerY + 10 : 0,
      color: img.ColorRgba8(255, 255, 255, 255),
    );

    // Iteratively compress with JPEG quality until under targetMaxBytes
    var quality = 80;
    var encoded = img.encodeJpg(resized, quality: quality);
    while (encoded.length > targetMaxBytes && quality > 20) {
      quality -= 15;
      encoded = img.encodeJpg(resized, quality: quality);
    }

    return Uint8List.fromList(encoded);
  }
}
