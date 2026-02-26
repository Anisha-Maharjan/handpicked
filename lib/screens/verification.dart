import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  static const Color _brown = Color(0xFF834D1E);
  static const Color _cream = Color(0xFFF6EED8);

  bool _sending = false;

  User? get _user => FirebaseAuth.instance.currentUser;

  Future<void> _sendVerificationEmail() async {
    final user = _user;
    if (user == null) return;

    setState(() => _sending = true);

    try {
      await user.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;

      if (refreshedUser == null) return;

      if (refreshedUser.emailVerified) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Your email is already verified.")),
        );
        return;
      }

      await refreshedUser.sendEmailVerification();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Verification link sent again.")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send email: $e")),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 10),

                Column(
                  children: [
                    Icon(
                      Icons.local_cafe_outlined,
                      size: 64,
                      color: _brown,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "HANDPICKED",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.0,
                        color: _brown,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "CARE IN EVERY SIP",
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.0,
                        color: _brown.withOpacity(0.75),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 34),

                // Main Card
                Container(
                  width: 330,
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _brown.withOpacity(0.55), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      // pill header
                      Container(
                        height: 40,
                        width: double.infinity,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _cream,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _brown.withOpacity(0.55)),
                        ),
                        child: const Text(
                          "Verification",
                          style: TextStyle(
                            color: _brown,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      const Text(
                        "Verification link has been sent\nto your email address.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _brown,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),

                      const SizedBox(height: 22),

                      SizedBox(
                        height: 44,
                        width: 220,
                        child: ElevatedButton(
                          onPressed: _sending ? null : _sendVerificationEmail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _brown,
                            disabledBackgroundColor: _brown.withOpacity(0.6),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Text(
                            _sending ? "Sending..." : "Send Again",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
