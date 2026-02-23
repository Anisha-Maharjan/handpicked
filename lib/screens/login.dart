import 'package:flutter/material.dart';
import 'package:handpicked/services/FirebaseAuthService.dart';
import 'package:handpicked/screens/homeScreen.dart';
import 'package:handpicked/screens/admin_home.dart';
import 'package:handpicked/screens/admin_login.dart';
import 'package:handpicked/screens/signup.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuthService _authService = FirebaseAuthService();

  bool _isLoginSelected = true;
  bool _obscurePassword = true;
  bool _isLoading = false;

  // --- UI colors to match screenshot ---
  static const Color _primary = Color(0xFF8B5A2B);
  static const Color _softFill = Color(0xFFF5E6D3);

  void _forgotPassword() async {
    final emailController = TextEditingController(text: _emailController.text.trim());

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            "Forgot Password",
            style: TextStyle(fontWeight: FontWeight.w700, color: _primary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Enter your email address and we'll send you a link to reset your password.",
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email",
                  labelStyle: const TextStyle(color: _primary, fontSize: 13),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: _primary),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: _primary, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel", style: TextStyle(color: _primary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => _isLoading = true);
                final result = await _authService
                    .sendPasswordResetEmail(emailController.text.trim());
                setState(() => _isLoading = false);

                if (!mounted) return;
                if (result.success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Password reset email sent. Check your inbox."),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  _showError(result.errorMessage ?? "Failed to send reset email.");
                }
              },
              child: const Text(
                "Send",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  void _signInWithGoogle() async {
    setState(() => _isLoading = true);
    final result = await _authService.signInWithGoogle();
    setState(() => _isLoading = false);

    if (!mounted) return;
    if (result.success && result.user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else {
      _showError(result.errorMessage ?? "Google sign-in failed.");
    }
  }

  void _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Validate inputs
    if (email.isEmpty) {
      _showError("Please enter your email");
      return;
    }

    if (password.isEmpty) {
      _showError("Please enter your password");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await _authService.signIn(email, password);

    setState(() {
      _isLoading = false;
    });

    if (result.success && result.user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else {
      _showError(result.errorMessage ?? "Login failed");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  InputDecoration _underlineDecoration({
    required String label,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      labelStyle: const TextStyle(
        color: _primary,
        fontSize: 12,
        height: 1.2,
      ),
      contentPadding: const EdgeInsets.only(top: 6, bottom: 10),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: _primary, width: 1),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: _primary, width: 1.2),
      ),
      suffixIcon: suffix,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 18),

                    // --- Top Logo — long-press to open Admin Login ---
                    GestureDetector(
                      onLongPress: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminLoginScreen(),
                          ),
                        );
                      },
                      child: Column(
                      children: const [
                        Text(
                          ")))",
                          style: TextStyle(
                            color: _primary,
                            fontSize: 16,
                            letterSpacing: 2,
                            height: 1,
                          ),
                        ),
                        SizedBox(height: 6),
                        Icon(Icons.coffee_rounded, size: 56, color: _primary),
                        SizedBox(height: 10),
                        Text(
                          "HANDPICKED",
                          style: TextStyle(
                            color: _primary,
                            fontSize: 18,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "CARE IN EVERY SIP",
                          style: TextStyle(
                            color: _primary,
                            fontSize: 11,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),   // end Column
                  ),     // end GestureDetector

                    const SizedBox(height: 26),

                    // --- Outer Rounded Container (border only) ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: _primary, width: 1),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // --- Login / Sign Up Toggle (pill) ---
                          Container(
                            decoration: BoxDecoration(
                              color: _softFill,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _primary, width: 1),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isLoginSelected = true;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _isLoginSelected
                                            ? _primary
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Text(
                                        "Login",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: _isLoginSelected
                                              ? Colors.white
                                              : _primary,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                SignUpScreen()),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: !_isLoginSelected
                                            ? _primary
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Text(
                                        "Sign Up",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: !_isLoginSelected
                                              ? Colors.white
                                              : _primary,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 22),

                          // --- Email ---
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            enabled: !_isLoading,
                            decoration: _underlineDecoration(label: "Email"),
                          ),

                          const SizedBox(height: 16),

                          // --- Password ---
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            enabled: !_isLoading,
                            decoration: _underlineDecoration(
                              label: "Password",
                              suffix: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: _primary,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 6),

                          // --- Forgot password (right aligned, brown) ---
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _isLoading ? null : _forgotPassword,
                              style: TextButton.styleFrom(
                                foregroundColor: _primary,
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                "Forgot password?",
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // --- Login Button ---
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primary,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                disabledBackgroundColor: _primary.withOpacity(0.6),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      "Login",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // --- or continue with (brown) ---
                          const Text(
                            "or continue with",
                            style: TextStyle(
                              color: _primary,
                              fontSize: 12,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // --- Google Button (outlined, rounded rectangle) ---
                          OutlinedButton.icon(
                            onPressed: _isLoading
                                ? null
                                : _signInWithGoogle,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: _primary, width: 1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 12,
                              ),
                            ),
                            icon: Image.network(
                              "https://www.google.com/favicon.ico",
                              width: 18,
                              height: 18,
                            ),
                            label: const Text(
                              "Google",
                              style: TextStyle(
                                color: _primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),
                        ],
                      ),
                    ),

                    const SizedBox(height: 26),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}