import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  static const Color _brown = Color(0xFF834D1E);
  static const Color _cream = Color(0xFFF6EED8);

  final _current = TextEditingController();
  final _newPass = TextEditingController();
  final _confirm = TextEditingController();

  bool _hideCurrent = true;
  bool _hideNew = true;
  bool _hideConfirm = true;

  bool _updating = false;

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  void dispose() {
    _current.dispose();
    _newPass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool _validPassword(String p) {
    // must include at least 8 characters, lowercase, uppercase, number
    if (p.length < 8) return false;
    final hasLower = RegExp(r'[a-z]').hasMatch(p);
    final hasUpper = RegExp(r'[A-Z]').hasMatch(p);
    final hasNum = RegExp(r'\d').hasMatch(p);
    return hasLower && hasUpper && hasNum;
  }

  Future<void> _updatePassword() async {
    final user = _user;
    if (user == null || user.email == null) return;

    final current = _current.text;
    final newPass = _newPass.text;
    final confirm = _confirm.text;

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields.")),
      );
      return;
    }

    if (!_validPassword(newPass)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Password must include at least 8 characters including lowercase, uppercase, and a number.",
          ),
        ),
      );
      return;
    }

    if (newPass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("New password and confirm password do not match.")),
      );
      return;
    }

    setState(() => _updating = true);

    try {
      //re-authenticate with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: current,
      );
      await user.reauthenticateWithCredential(credential);

      //update password
      await user.updatePassword(newPass);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password updated successfully.")),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String msg = "Failed to update password.";
      if (e.code == 'wrong-password') msg = "Current password is incorrect.";
      if (e.code == 'weak-password') msg = "New password is too weak.";
      if (e.code == 'requires-recent-login') {
        msg = "Please login again and try updating your password.";
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update password: $e")),
      );
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Widget _linePasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback toggle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _brown,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscure,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              IconButton(
                onPressed: toggle,
                icon: Icon(
                  obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: _brown,
                  size: 18,
                ),
              ),
            ],
          ),
          Container(height: 1, color: _brown.withOpacity(0.45)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(24),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: _brown,
                          ),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Column(
                    children: [
                      Icon(Icons.local_cafe_outlined, size: 62, color: _brown),
                      const SizedBox(height: 8),
                      const Text(
                        "HANDPICKED",
                        style: TextStyle(
                          color: _brown,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "CARE IN EVERY SIP",
                        style: TextStyle(
                          color: _brown.withOpacity(0.75),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  Container(
                    width: 330,
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _brown.withOpacity(0.55), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                            "Reset Password",
                            style: TextStyle(
                              color: _brown,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        Text(
                          "Password must include at least 8 characters\nincluding a lowercase, uppercase, and a number.",
                          style: TextStyle(
                            color: _brown.withOpacity(0.85),
                            fontSize: 11.2,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),

                        const SizedBox(height: 16),

                        _linePasswordField(
                          label: "Current Password",
                          controller: _current,
                          obscure: _hideCurrent,
                          toggle: () => setState(() => _hideCurrent = !_hideCurrent),
                        ),
                        _linePasswordField(
                          label: "New Password",
                          controller: _newPass,
                          obscure: _hideNew,
                          toggle: () => setState(() => _hideNew = !_hideNew),
                        ),
                        _linePasswordField(
                          label: "Confirm password",
                          controller: _confirm,
                          obscure: _hideConfirm,
                          toggle: () => setState(() => _hideConfirm = !_hideConfirm),
                        ),

                        const SizedBox(height: 22),

                        Center(
                          child: SizedBox(
                            height: 44,
                            width: 240,
                            child: ElevatedButton(
                              onPressed: _updating ? null : _updatePassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _brown,
                                disabledBackgroundColor: _brown.withOpacity(0.6),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(26),
                                ),
                              ),
                              child: Text(
                                _updating ? "Updating..." : "Update",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        if (_updating)
          Container(
            color: Colors.black.withOpacity(0.18),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
