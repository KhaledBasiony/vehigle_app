import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_car_sim/common/db.dart';
import 'package:mobile_car_sim/common/theme.dart';
import 'package:mobile_car_sim/pages/home.dart';
import 'package:mobile_car_sim/pages/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Db.open();
  runApp(const ExampleApplication());
}

class ExampleApplication extends StatelessWidget {
  const ExampleApplication({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(Db.instance.read<double>(textScaleFactor) ?? 1.0),
            ),
            child: child!,
          );
        },
        theme: AppTheme.instance.theme,
        routes: {
          '/login': (context) => const LoginPage(),
          '/home/user': (context) => const HomePage(isUser: true),
          '/home/developer': (context) => const HomePage(),
        },
        home: const LoginPage(),
      ),
    );
  }
}
