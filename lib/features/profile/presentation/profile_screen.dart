import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'profile_notifier.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _upiController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _upiController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  void _populateFields(ProfileState state) {
    if (_initialized) return;
    final friend = state.userProfile?.accountabilityFriend;
    if (friend != null) {
      _nameController.text = friend.name;
      _phoneController.text = friend.phoneE164;
      _upiController.text = friend.upiVpa;
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileNotifierProvider);
    _populateFields(state);

    final emerald = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Accountability Profile',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: state.isLoading && state.userProfile == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: emerald.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: emerald.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: emerald,
                            child: Text(
                              (state.userProfile?.name.isNotEmpty == true)
                                  ? state.userProfile!.name[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state.userProfile?.name ?? 'GrowthStreak Student',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  state.userProfile?.email ?? '',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Accountability Friend',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: emerald,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'This friend receives your gym proof photos on WhatsApp and approves or rejects them. They hold you accountable.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Friend Name
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: "Friend's Full Name",
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) => (value == null || value.trim().isEmpty)
                          ? "Please enter friend's name"
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // WhatsApp Phone
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: "Friend's WhatsApp Number",
                        hintText: "+919876543210",
                        prefixIcon: const Icon(Icons.phone_android_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Please enter phone number";
                        }
                        if (!value.startsWith('+') || value.length < 10) {
                          return "Include country code (e.g. +91...)";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Friend UPI VPA
                    TextFormField(
                      controller: _upiController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "Friend's UPI VPA (for accountability stake)",
                        hintText: "friend@oksbi or 9876543210@paytm",
                        prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Please enter UPI VPA";
                        }
                        if (!value.contains('@')) {
                          return "Enter a valid UPI ID (e.g. friend@upi)";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    if (state.errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                state.errorMessage!,
                                style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (state.isSaved)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline, color: Colors.green.shade700, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Friend details saved successfully!',
                              style: TextStyle(color: Colors.green.shade700, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: emerald,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: state.isLoading
                            ? null
                            : () async {
                                if (_formKey.currentState?.validate() ?? false) {
                                  await ref
                                      .read(profileNotifierProvider.notifier)
                                      .updateAccountabilityFriend(
                                        name: _nameController.text,
                                        phoneE164: _phoneController.text,
                                        upiVpa: _upiController.text,
                                      );
                                }
                              },
                        child: state.isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Save Accountability Friend',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
