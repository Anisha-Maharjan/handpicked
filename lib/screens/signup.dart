import 'package:flutter/material.dart';
import 'package:handpicked/services/FirebaseAuthService.dart';
import 'package:handpicked/screens/verification.dart';
import 'package:handpicked/screens/login.dart';
import 'package:handpicked/screens/homeScreen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();
  final FirebaseAuthService _authService = FirebaseAuthService();
  
  bool _isLoginSelected = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  static const Color _primary = Color(0xFF8B5A2B);
  static const Color _softFill = Color(0xFFF5E6D3);

  // Sign-up method with improved error handling
  void _signUpWithGoogle() async {
    setState(() => _isLoading = true);
    final result = await _authService.signInWithGoogle();
    setState(() => _isLoading = false);

    if (!mounted) return;
    if (result.success && result.user != null) {
      // Google accounts are pre-verified, go straight to HomeScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else {
      _showError(result.errorMessage ?? "Google sign-up failed.");
    }
  }

  // Sign-up method with improved error handling
  void _signUp() async {
    // Validate inputs first
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final username = _usernameController.text.trim();

    // Check if fields are empty
    if (email.isEmpty) {
      _showError("Please enter your email");
      return;
    }

    if (username.isEmpty) {
      _showError("Please enter a username");
      return;
    }

    if (password.isEmpty) {
      _showError("Please enter a password");
      return;
    }

    if (confirmPassword.isEmpty) {
      _showError("Please confirm your password");
      return;
    }

    // Check if passwords match
    if (password != confirmPassword) {
      _showError("Passwords do not match");
      return;
    }

    // Check password length
    if (password.length < 6) {
      _showError("Password must be at least 6 characters");
      return;
    }

    // Show loading
    setState(() {
      _isLoading = true;
    });

    try {
      // Call sign-up method from FirebaseAuthService
      final result = await _authService.signUp(email, password, username, "user");

      setState(() {
        _isLoading = false;
      });

      if (result.success && result.user != null) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Account created! Please check your email for verification."),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Navigate to verification screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => VerificationScreen()),
        );
      } else {
        // Show specific error message from AuthResult
        _showError(result.errorMessage ?? "Sign up failed. Please try again.");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError("An unexpected error occurred: ${e.toString()}");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
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

                    // --- Top Logo ---
                    Column(
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
                    ),

                    const SizedBox(height: 26),

                    //Outer Rounded Container
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
                          //Login / Sign Up Toggle
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
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => LoginScreen(),
                                        ),
                                      );
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
                                      setState(() {
                                        _isLoginSelected = false;
                                      });
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

                          //Username
                          TextField(
                            controller: _usernameController,
                            enabled: !_isLoading,
                            decoration: _underlineDecoration(label: "Username"),
                          ),

                          const SizedBox(height: 16),

                          //Email
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            enabled: !_isLoading,
                            decoration: _underlineDecoration(label: "Email"),
                          ),

                          const SizedBox(height: 16),

                          //Password
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

                          const SizedBox(height: 16),

                          //Confirm Password
                          TextField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            enabled: !_isLoading,
                            decoration: _underlineDecoration(
                              label: "Confirm password",
                              suffix: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: _primary,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          //Sign Up Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _signUp,
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
                                      "Sign Up",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          //or continue with
                          const Text(
                            "or continue with",
                            style: TextStyle(
                              color: _primary,
                              fontSize: 12,
                            ),
                          ),

                          const SizedBox(height: 12),

                          //Google Button
                          OutlinedButton.icon(
                            onPressed: _isLoading
                                ? null
                                : _signUpWithGoogle,
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