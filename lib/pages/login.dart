import 'package:flutter/material.dart';
import 'package:mobile_car_sim/common/theme.dart';
import 'package:mobile_car_sim/common/widgets.dart';

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
    final textStyle = TextStyle(fontSize: 32, color: AppTheme.instance.primaryColor);
    final userLoginButton = SemiCircularButton(
      onPressed: () => _userLogin(context),
      reverseDirection: true,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'User Login',
          style: textStyle,
        ),
      ),
    );
    final developerLoginButton = SemiCircularButton(
      onPressed: () => _developerLogin(context),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'Developer Login',
          style: textStyle,
        ),
      ),
    );

    return Scaffold(
      body: Center(
        child: IntrinsicWidth(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              userLoginButton,
              const SizedBox(height: 10),
              developerLoginButton,
            ],
          ),
        ),
      ),
    );
  }
}
