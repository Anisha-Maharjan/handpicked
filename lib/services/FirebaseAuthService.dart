import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthResult {
  final User? user;
  final String? errorMessage;
  final bool success;
  final String? role; // 'admin' | 'user' | null

  AuthResult({this.user, this.errorMessage, this.success = false, this.role});
}

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign up with email, password, username, and role
  Future<AuthResult> signUp(
    String email,
    String password,
    String username,
    String role,
  ) async {
    User? createdUser;
    
    try {
      print("=== SIGNUP DEBUG START ===");
      print("Email: $email");
      print("Username: $username");
      print("Role: $role");
      
      // 1) Create user in Firebase Auth
      print("Step 1: Creating user in Firebase Auth...");
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final User? user = userCredential.user;
      createdUser = user; // Store reference for potential rollback

      if (user == null) {
        print("ERROR: User is null after auth creation");
        return AuthResult(
          success: false,
          errorMessage: "Failed to create user account",
        );
      }

      print("SUCCESS: User created in Firebase Auth with UID: ${user.uid}");

      // 2) Save user data to Firestore
      print("Step 2: Saving user data to Firestore...");
      
      try {
        final data = <String, dynamic>{
          'username': username.trim(),
          'email': user.email,
          'role': role == 'admin' ? 'admin' : 'user',
          'emailVerified': false,
          'createdAt': FieldValue.serverTimestamp(),
        };

        final collection = role == 'admin' ? 'admin' : 'users';
        print("Collection: $collection");
        print("Document ID: ${user.uid}");
        print("Data to save: $data");

        // Check if Firestore is accessible
        print("Testing Firestore connection...");
        await _firestore.collection(collection).doc(user.uid).set(data);
        
        print("SUCCESS: User data saved to Firestore");
        
      } catch (firestoreError) {
        print("ERROR during Firestore write: $firestoreError");
        print("Error type: ${firestoreError.runtimeType}");
        
        if (firestoreError is FirebaseException) {
          print("Firebase error code: ${firestoreError.code}");
          print("Firebase error message: ${firestoreError.message}");
        }
        
        // If Firestore fails, delete the auth user to maintain consistency
        print("Rolling back: Deleting auth user...");
        try {
          await user.delete();
          print("SUCCESS: Auth user deleted");
        } catch (deleteError) {
          print("ERROR: Could not delete auth user: $deleteError");
        }
        
        return AuthResult(
          success: false,
          errorMessage: "Failed to save user data: ${firestoreError.toString()}",
        );
      }

      // 3) Send verification email
      print("Step 3: Sending verification email...");
      try {
        if (!user.emailVerified) {
          await user.sendEmailVerification();
          print("SUCCESS: Verification email sent to ${user.email}");
        }
      } catch (emailError) {
        print("WARNING: Failed to send verification email: $emailError");
        // Don't fail signup if email sending fails, user can resend later
      }

      print("=== SIGNUP COMPLETED SUCCESSFULLY ===");
      
      // ✅ Signup SUCCESS
      return AuthResult(
        success: true,
        user: user,
        errorMessage: null,
      );
      
    } on FirebaseAuthException catch (e) {
      print("=== FIREBASE AUTH EXCEPTION ===");
      print("Code: ${e.code}");
      print("Message: ${e.message}");
      
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = "This email is already registered. Please login instead.";
          break;
        case 'invalid-email':
          errorMessage = "Invalid email address format.";
          break;
        case 'weak-password':
          errorMessage = "Password is too weak. Use at least 6 characters.";
          break;
        case 'network-request-failed':
          errorMessage = "Network error. Please check your internet connection.";
          break;
        default:
          errorMessage = "Sign up failed: ${e.message ?? 'Unknown error'}";
      }
      
      return AuthResult(
        success: false,
        errorMessage: errorMessage,
      );
      
    } on FirebaseException catch (e) {
      print("=== FIREBASE EXCEPTION ===");
      print("Code: ${e.code}");
      print("Message: ${e.message}");
      print("Plugin: ${e.plugin}");
      
      return AuthResult(
        success: false,
        errorMessage: "Database error: ${e.message ?? 'Unknown error'}",
      );
      
    } catch (e) {
      print("=== UNKNOWN EXCEPTION ===");
      print("Error: $e");
      print("Type: ${e.runtimeType}");
      
      return AuthResult(
        success: false,
        errorMessage: "An unexpected error occurred: ${e.toString()}",
      );
    }
  }

  // Sign in with email and password
  Future<AuthResult> signIn(String email, String password) async {
    try {
      print("=== LOGIN DEBUG START ===");
      print("Attempting sign in for email: $email");
      
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      print("SUCCESS: Sign in successful for user: ${userCredential.user?.uid}");

      // Fetch role from Firestore (admins collection checked first)
      final role = userCredential.user != null
          ? await getUserRole(userCredential.user!.uid)
          : null;

      print("User role resolved: $role");
      print("=== LOGIN COMPLETED SUCCESSFULLY ===");

      return AuthResult(
        success: true,
        user: userCredential.user,
        role: role,
      );
      
    } on FirebaseAuthException catch (e) {
      print("=== LOGIN FIREBASE AUTH EXCEPTION ===");
      print("Code: ${e.code}");
      print("Message: ${e.message}");
      
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = "No account found with this email.";
          break;
        case 'wrong-password':
          errorMessage = "Incorrect password.";
          break;
        case 'invalid-email':
          errorMessage = "Invalid email address format.";
          break;
        case 'user-disabled':
          errorMessage = "This account has been disabled.";
          break;
        case 'network-request-failed':
          errorMessage = "Network error. Please check your internet connection.";
          break;
        case 'invalid-credential':
          errorMessage = "Invalid email or password.";
          break;
        default:
          errorMessage = "Login failed: ${e.message ?? 'Unknown error'}";
      }
      
      return AuthResult(
        success: false,
        errorMessage: errorMessage,
      );
      
    } catch (e) {
      print("=== LOGIN UNKNOWN EXCEPTION ===");
      print("Error: $e");
      print("Type: ${e.runtimeType}");
      
      return AuthResult(
        success: false,
        errorMessage: "An unexpected error occurred: ${e.toString()}",
      );
    }
  }

  // Sign out
  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  /// Checks Firestore to determine if the user is an 'admin' or 'user'.
  /// Looks in the 'admins' collection first, then 'users'.
  /// Returns null if no document is found in either collection.
  Future<String?> getUserRole(String uid) async {
    try {
      // Check admins collection first
      final adminDoc = await _firestore.collection('admin').doc(uid).get();
      if (adminDoc.exists) {
        final data = adminDoc.data();
        final role = data?['role'] as String?;
        return (role != null && role.isNotEmpty) ? role : 'admin';
      }

      // Fall back to users collection
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        final role = data?['role'] as String?;
        return (role != null && role.isNotEmpty) ? role : 'user';
      }

      return null; // Not found in either collection
    } catch (e) {
      print("ERROR fetching user role: $e");
      return null;
    }
  }

  // Send password reset email
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      if (email.trim().isEmpty) {
        return AuthResult(
          success: false,
          errorMessage: "Please enter your email address.",
        );
      }
      await _auth.sendPasswordResetEmail(email: email.trim());
      return AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = "No account found with this email address.";
          break;
        case 'invalid-email':
          errorMessage = "Invalid email address format.";
          break;
        case 'too-many-requests':
          errorMessage = "Too many attempts. Please try again later.";
          break;
        default:
          errorMessage = "Failed to send reset email: ${e.message ?? 'Unknown error'}";
      }
      return AuthResult(success: false, errorMessage: errorMessage);
    } catch (e) {
      return AuthResult(
        success: false,
        errorMessage: "An unexpected error occurred: ${e.toString()}",
      );
    }
  }

  // Sign in / Sign up with Google
  Future<AuthResult> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        return AuthResult(success: false, errorMessage: "Google sign-in cancelled.");
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      final User? user = userCredential.user;
      if (user == null) {
        return AuthResult(success: false, errorMessage: "Failed to sign in with Google.");
      }

      // If new user, create Firestore document
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
      if (isNewUser) {
        final nameParts = (user.displayName ?? '').trim().split(' ');
        final firstName = nameParts.isNotEmpty ? nameParts.first : '';
        final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

        await _firestore.collection('users').doc(user.uid).set({
          'username': user.displayName ?? user.email ?? '',
          'firstName': firstName,
          'lastName': lastName,
          'email': user.email,
          'photoUrl': user.photoURL,
          'role': 'user',
          'emailVerified': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return AuthResult(success: true, user: user);
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          errorMessage =
              "An account already exists with the same email but different sign-in method.";
          break;
        case 'network-request-failed':
          errorMessage = "Network error. Please check your internet connection.";
          break;
        default:
          errorMessage = "Google sign-in failed: ${e.message ?? 'Unknown error'}";
      }
      return AuthResult(success: false, errorMessage: errorMessage);
    } catch (e) {
      return AuthResult(
        success: false,
        errorMessage: "Google sign-in failed: ${e.toString()}",
      );
    }
  }
}