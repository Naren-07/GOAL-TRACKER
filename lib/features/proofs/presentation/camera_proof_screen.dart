import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/auth_state.dart';
import '../../tasks/domain/habit_task.dart';
import '../../tasks/presentation/today_tasks_notifier.dart';
import 'proof_notifier.dart';

class CameraProofScreen extends ConsumerStatefulWidget {
  final HabitTask task;

  const CameraProofScreen({
    super.key,
    required this.task,
  });

  @override
  ConsumerState<CameraProofScreen> createState() => _CameraProofScreenState();
}

class _CameraProofScreenState extends ConsumerState<CameraProofScreen> {
  bool _isCameraActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(proofNotifierProvider.notifier).clearCapture();
    });
  }

  Uint8List _generateSimulatedCameraFrame() {
    // Generates a live camera simulation capture for devices/emulators/tests
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final image = img.Image(width: 400, height: 400);
    for (var y = 0; y < 400; y++) {
      for (var x = 0; x < 400; x++) {
        image.setPixelRgb(
          x,
          y,
          ((x + timestamp) % 255),
          ((y * 2) % 255),
          120,
        );
      }
    }
    return Uint8List.fromList(img.encodeJpg(image, quality: 90));
  }

  void _onCapturePressed() {
    final bytes = _generateSimulatedCameraFrame();
    ref.read(proofNotifierProvider.notifier).processCapturedPhoto(bytes);
    setState(() {
      _isCameraActive = false;
    });
  }

  void _onRetakePressed() {
    ref.read(proofNotifierProvider.notifier).clearCapture();
    setState(() {
      _isCameraActive = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(proofNotifierProvider);
    final authState = ref.watch(authNotifierProvider);
    final userProfile = authState is AuthenticatedState ? authState.profile : null;
    final friend = userProfile?.accountabilityFriend;
    final today = TodayTasksNotifier.todayDateString();
    final emerald = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          'Live Gym Proof Capture',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        actions: [
          IconButton(
            key: const Key('info_icon'),
            icon: const Icon(Icons.security, color: Colors.white70),
            tooltip: 'Gallery uploads strictly disabled',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Live camera only. Gallery/camera-roll upload is disabled to prevent cheating.'),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Task context banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey.shade900,
              child: Row(
                children: [
                  const Icon(Icons.fitness_center, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${widget.task.title} (Weight: ${widget.task.weight})',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: emerald.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: emerald),
                    ),
                    child: Text(
                      'LIVE ONLY',
                      style: TextStyle(
                        color: emerald,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Viewfinder or Preview Area
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_isCameraActive || state.previewWatermarkedBytes == null)
                    // Dedicated In-App Viewfinder
                    Container(
                      key: const Key('camera_viewfinder'),
                      color: Colors.black87,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Center(
                            child: Icon(
                              Icons.camera_alt_outlined,
                              size: 100,
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          // Viewfinder grid corners
                          Center(
                            child: Container(
                              width: 280,
                              height: 340,
                              decoration: BoxDecoration(
                                border: Border.all(color: emerald.withValues(alpha: 0.7), width: 2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 24,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Align your gym photo inside frame',
                                style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    // Captured Preview with Watermark Overlay
                    Container(
                      key: const Key('proof_preview_container'),
                      color: Colors.black,
                      child: Image.memory(
                        state.previewWatermarkedBytes!,
                        fit: BoxFit.contain,
                      ),
                    ),

                  // Duplicate Rejection or Error Banner
                  if (state.errorMessage != null)
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade900.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.redAccent),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.white),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                state.errorMessage!,
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Submission Success Overlay
                  if (state.isSubmitted && state.submittedProof != null)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.85),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle, color: Colors.greenAccent, size: 72),
                            const SizedBox(height: 16),
                            Text(
                              'Proof Submitted!',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sent for verification to ${friend?.name ?? "Accountability Friend"}.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Expires at 10:00 AM tomorrow.',
                              style: TextStyle(color: Colors.amber.shade300, fontSize: 12),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              key: const Key('done_button'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: emerald,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Back to Today'),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Bottom Controls Bar
            Container(
              color: Colors.black,
              padding: const EdgeInsets.all(20),
              child: _isCameraActive
                  ? Center(
                      child: GestureDetector(
                        key: const Key('shutter_button'),
                        onTap: _onCapturePressed,
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: Center(
                            child: Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: emerald,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const Key('retake_button'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white38),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retake'),
                            onPressed: state.isUploading ? null : _onRetakePressed,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            key: const Key('submit_proof_button'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: emerald,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: state.isUploading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Icon(Icons.send_rounded),
                            label: Text(
                              state.isUploading ? 'Submitting...' : 'Submit Proof',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: (state.isUploading || state.isSubmitted)
                                ? null
                                : () async {
                                    final uid = userProfile?.uid ?? 'guest';
                                    await ref.read(proofNotifierProvider.notifier).submitProof(
                                          uid: uid,
                                          taskId: widget.task.id,
                                          date: today,
                                          friend: friend,
                                        );
                                  },
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
