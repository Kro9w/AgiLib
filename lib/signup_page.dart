import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: "https://agilib-29cf3-default-rtdb.asia-southeast1.firebasedatabase.app",
  );

  bool isStrongPassword(String password) {
    final hasUpper = password.contains(RegExp(r'[A-Z]'));
    final hasSymbol = password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
    final hasMinLength = password.length >= 8;
    return hasUpper && hasSymbol && hasMinLength;
  }

  bool isValidId(String id) {
    return RegExp(r'^\d{2}-\d{5}$').hasMatch(id);
  }

  Future<void> signUp() async {
    final name = _nameController.text.trim();
    final surname = _surnameController.text.trim();
    final id = _idController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty || surname.isEmpty || id.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      showError("Please fill in all fields.");
      return;
    }

    if (!isValidId(id)) {
      showError("ID must follow the format XX-XXXXX (e.g., 22-10055).");
      return;
    }

    if (password != confirmPassword) {
      showError("Passwords do not match.");
      return;
    }

    if (!isStrongPassword(password)) {
      showError("Password must be at least 8 characters long, with one uppercase letter and one symbol.");
      return;
    }

    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      // Upload user data to Realtime Database
      await database.ref('users/$uid').set({
        'name': name,
        'surname': surname,
        'id': id,
        'email': email,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signup Successful! Please log in.'),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(top: 16, left: 16, right: 16),
          ),
        );
      }

      await Future.delayed(const Duration(seconds: 2));
      await FirebaseAuth.instance.signOut();

      if (context.mounted) {
        Navigator.of(context).pop(); // Go back to login
      }
    } on FirebaseAuthException catch (e) {
      showError("Signup Error: ${e.message ?? e.code}");
    }
  }

  void showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Signup')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'First Name'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _surnameController,
                    decoration: const InputDecoration(labelText: 'Surname'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _idController,
              decoration: const InputDecoration(
                labelText: 'ID Number (XX-XXXXX)',
                hintText: 'e.g. 22-10055',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm Password'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: signUp,
              child: const Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}