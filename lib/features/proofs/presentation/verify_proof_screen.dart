import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../domain/proof.dart';
import 'proof_providers.dart';

class VerifyProofScreen extends ConsumerStatefulWidget {
  final String proofId;
  final String? token;

  const VerifyProofScreen({
    super.key,
    required this.proofId,
    this.token,
  });

  @override
  ConsumerState<VerifyProofScreen> createState() => _VerifyProofScreenState();
}

class _VerifyProofScreenState extends ConsumerState<VerifyProofScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Proof? _proof;
  bool _isDecided = false;
  String? _decisionStatus;

  @override
  void initState() {
    super.initState();
    _loadProof();
  }

  Future<void> _loadProof() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final repo = ref.read(proofRepositoryProvider);
    try {
      final proof = await repo.getProof(widget.proofId);
      if (proof == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Proof record not found.';
        });
        return;
      }

      // Verify cryptographic token nonce
      if (widget.token != null && proof.tokenNonce != widget.token) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid or unauthorized verification token.';
        });
        return;
      }

      setState(() {
        _isLoading = false;
        _proof = proof;
        if (!proof.isPending) {
          _isDecided = true;
          _decisionStatus = proof.status;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading proof: ${e.toString()}';
      });
    }
  }

  Future<void> _approve() async {
    if (_proof == null) return;
    setState(() => _isLoading = true);
    final repo = ref.read(proofRepositoryProvider);
    await repo.updateProofStatus(_proof!.id, 'approved');
    setState(() {
      _isLoading = false;
      _isDecided = true;
      _decisionStatus = 'approved';
    });
  }

  Future<void> _reject(String reason) async {
    if (_proof == null) return;
    setState(() => _isLoading = true);
    final repo = ref.read(proofRepositoryProvider);
    await repo.updateProofStatus(_proof!.id, 'rejected', rejectionReason: reason);
    setState(() {
      _isLoading = false;
      _isDecided = true;
      _decisionStatus = 'rejected';
    });
  }

  void _showRejectDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final reasons = ['Not at gym', 'Old photo', 'Blurry / Unclear', 'Other'];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Rejection Reason',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...reasons.map((r) => ListTile(
                      title: Text(r),
                      leading: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        _reject(r);
                      },
                    )),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const emerald = Color(0xFF0B5D45);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('GrowthStreak Proof Verification')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final proof = _proof!;
    final isExpired = DateTime.now().isAfter(proof.expiresAt);

    // Expired or Already Decided Status Card
    if (isExpired && !_isDecided) {
      return Scaffold(
        appBar: AppBar(title: const Text('Proof Review')),
        body: Center(
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_off_outlined, size: 56, color: Colors.orange),
                  const SizedBox(height: 16),
                  Text(
                    'Link Expired',
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This verification token expired at 10:00 AM grace cutoff passed.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_isDecided) {
      final isApproved = _decisionStatus == 'approved';
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isApproved ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: isApproved ? emerald : Colors.redAccent,
                    size: 80,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isApproved ? 'Gym Proof Approved! 🎉' : 'Proof Rejected',
                    style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isApproved
                        ? 'Student streak is preserved and task completed.'
                        : 'Student has been notified of the rejection.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final formattedTimestamp =
        DateFormat('dd MMM yyyy, hh:mm a').format(proof.createdAt);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Friend Proof Review',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Student Header Badge
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: emerald,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            proof.friendName != null
                                ? 'Reviewing for your friend'
                                : 'Gym Accountability Verification',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            'Workout Proof',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Captured: $formattedTimestamp',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Watermarked Full Photo Preview
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  color: Colors.black,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: proof.photoUrl.startsWith('http')
                        ? Image.network(
                            proof.photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Center(
                              child: Icon(Icons.broken_image, color: Colors.white54, size: 48),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.fitness_center, color: Colors.white, size: 64),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons: Approve & Reject
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('reject_proof_button'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: _showRejectDialog,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      key: const Key('approve_proof_button'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: emerald,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text(
                        'Approve Workout',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      onPressed: _approve,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
