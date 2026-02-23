import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

//Navigation screens
import 'package:handpicked/screens/edit_profile.dart';
import 'package:handpicked/screens/reset_password.dart';
import 'package:handpicked/screens/login.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Color _brown = Color(0xFF834D1E);

  bool _deleting = false;

  Future<void> _deleteAccountFlow() async {
    // 1) Confirm
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Text(
            "Delete Account",
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: const Text(
            "Are you sure you want to delete your account?\nThis action cannot be undone.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedIndexButtonStyle.brown(),
              child: const Text(
                "Delete",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    // 2) Delete from Firebase
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // already signed out
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginScreen()),
        (route) => false,
      );
      return;
    }

    setState(() => _deleting = true);

    try {
      final uid = user.uid;

      //delete Firestore user data first
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();

      //then delete the auth account
      await user.delete();

      //ensure signed out state
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      // This is common: Firebase requires "recent login" to delete account
      if (e.code == 'requires-recent-login') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "For security, please login again and then delete your account.",
            ),
          ),
        );

        // Optional: send them to login so they can re-login
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => LoginScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete account: ${e.message}")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete account: $e")),
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //Top bar like screenshot
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(24),
                        child: const Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: _brown,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        "Settings",
                        style: TextStyle(
                          color: _brown,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                //Edit Profile (navigate)
                _SettingsItem(
                  icon: Icons.person_outline_rounded,
                  title: "Edit Profile",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => EditProfileScreen()),
                    );
                  },
                ),

                //Delete Account (NO navigation, popup + delete)
                _SettingsItem(
                  icon: Icons.delete_outline_rounded,
                  title: "Delete Account",
                  onTap: _deleting ? null : _deleteAccountFlow,
                ),

                //Change Password (navigate)
                _SettingsItem(
                  icon: Icons.lock_outline_rounded,
                  title: "Change Password",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ResetPasswordScreen()),
                    );
                  },
                ),

                _SettingsItem(
                  icon: Icons.description_outlined,
                  title: "Terms and Condition",
                  onTap: () {
                    // do nothing
                  },
                  showChevron: true,
                ),

                const Spacer(),
              ],
            ),
          ),
        ),

        //simple blocking loader while deleting
        if (_deleting)
          Container(
            color: Colors.black.withOpacity(0.25),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final bool showChevron;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.showChevron = true,
  });

  static const Color _brown = Color(0xFF834D1E);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: _brown),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: _brown,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (showChevron)
              Icon(
                Icons.chevron_right_rounded,
                color: _brown.withOpacity(0.8),
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

class ElevatedIndexButtonStyle {
  static ButtonStyle brown() {
    return ElevatedButton.styleFrom(
      backgroundColor: _SettingsScreenState._brown,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
