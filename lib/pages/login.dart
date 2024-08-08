import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  void _userLogin(BuildContext context) {
    Navigator.popAndPushNamed(context, '/home/user');
  }

  void _developerLogin(BuildContext context) {
    Navigator.popAndPushNamed(context, '/home/developer');
  }

  @override
  Widget build(BuildContext context) {
    final userLoginButton = ElevatedButton(
      onPressed: () => _userLogin(context),
      child: const Text('User Login'),
    );
    final developerLoginButton = ElevatedButton(
      onPressed: () => _developerLogin(context),
      child: const Text('Developer Login'),
    );

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            userLoginButton,
            const SizedBox(height: 10),
            developerLoginButton,
          ],
        ),
      ),
    );
  }
}
