import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:handpicked/services/FirebaseAuthService.dart';
import 'package:handpicked/screens/admin_home.dart';

const String _kAdminAccessCode = 'admin123';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  static const Color _brown = Color(0xFF7B4A1E);
  static const Color _cream = Color(0xFFF6EED8);

  final _authService          = FirebaseAuthService();
  final _emailController      = TextEditingController();
  final _passwordController   = TextEditingController();
  final _accessCodeController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureCode     = true;
  bool _isLoading       = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _accessCodeController.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  Future<void> _adminLogin() async {
    final email      = _emailController.text.trim();
    final password   = _passwordController.text;
    final accessCode = _accessCodeController.text.trim();

    if (email.isEmpty || password.isEmpty || accessCode.isEmpty) {
      _showError('Please fill in all fields.');
      return;
    }

    //Check secret access code first
    if (accessCode != _kAdminAccessCode) {
      _showError('Invalid admin access code.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      //Use the same FirebaseAuthService.signIn as the regular login
      final result = await _authService.signIn(email, password);

      if (!result.success || result.user == null) {
        _showError(result.errorMessage ?? 'Login failed.');
        return;
      }

      //Verify UID exists in admin collection
      final adminDoc = await FirebaseFirestore.instance
          .collection('admin')
          .doc(result.user!.uid)
          .get();

      if (!adminDoc.exists) {
        // Signed in to Firebase Auth but not an admin — sign out immediately
        await _authService.signOut();
        _showError('This account does not have admin privileges.');
        return;
      }

      //All good — navigate to admin dashboard
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(
            builder: (_) => AdminHomeScreen(user: result.user!)),
        (route) => false,
      );
    } catch (e) {
      _showError('An unexpected error occurred: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color:      _brown,
              fontSize:   12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(icon, color: _brown.withOpacity(0.5), size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller:   controller,
                  obscureText:  obscure,
                  keyboardType: keyboardType,
                  style: const TextStyle(
                    color:      Colors.black87,
                    fontSize:   13,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    isDense:        true,
                    border:         InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (onToggleObscure != null)
                GestureDetector(
                  onTap: onToggleObscure,
                  child: Icon(
                    obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: _brown.withOpacity(0.5),
                    size:  16,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Container(height: 1, color: _brown.withOpacity(0.3)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                //Brand 
                const Icon(Icons.local_cafe_outlined, color: _brown, size: 58),
                const SizedBox(height: 8),
                const Text(
                  'HANDPICKED',
                  style: TextStyle(
                    color:         _brown,
                    fontSize:      20,
                    fontWeight:    FontWeight.w800,
                    letterSpacing: 2.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ADMIN PORTAL',
                  style: TextStyle(
                    color:         _brown.withOpacity(0.6),
                    fontSize:      11,
                    fontWeight:    FontWeight.w700,
                    letterSpacing: 2.0,
                  ),
                ),

                const SizedBox(height: 36),

                //Card 
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  decoration: BoxDecoration(
                    color:        Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _brown.withOpacity(0.5), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pill header
                      Container(
                        height:    40,
                        width:     double.infinity,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color:        _cream,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _brown.withOpacity(0.4)),
                        ),
                        child: const Text(
                          'Admin Login',
                          style: TextStyle(
                            color:      _brown,
                            fontSize:   13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      _field(
                        label:        'Email',
                        controller:   _emailController,
                        icon:         Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      _field(
                        label:           'Password',
                        controller:      _passwordController,
                        icon:            Icons.lock_outline_rounded,
                        obscure:         _obscurePassword,
                        onToggleObscure: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                      _field(
                        label:           'Admin Access Code',
                        controller:      _accessCodeController,
                        icon:            Icons.vpn_key_outlined,
                        obscure:         _obscureCode,
                        onToggleObscure: () =>
                            setState(() => _obscureCode = !_obscureCode),
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width:  double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _adminLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:         _brown,
                            disabledBackgroundColor: _brown.withOpacity(0.6),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width:  20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color:       Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Login as Admin',
                                  style: TextStyle(
                                    color:      Colors.white,
                                    fontSize:   14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text(
                    '← Back to user login',
                    style: TextStyle(
                      color:      _brown.withOpacity(0.7),
                      fontSize:   12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}