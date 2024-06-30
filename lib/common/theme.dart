import 'package:flutter/material.dart';
import 'package:mobile_car_sim/common/db.dart';

class AppTheme {
  AppTheme._({required bool useLight}) : primaryColor = useLight ? Colors.lightBlue : Colors.blueAccent {
    theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        brightness: useLight ? Brightness.light : Brightness.dark,
        seedColor: primaryColor,
      ),
    );
  }

  static AppTheme? _instance;
  static AppTheme get instance => _instance ??= AppTheme._(useLight: Db.instance.read<bool>(useLightTheme) ?? false);

  late final ThemeData theme;
  final Color primaryColor;
}
