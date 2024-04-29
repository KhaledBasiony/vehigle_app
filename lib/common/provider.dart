import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final gyroEventProvider = StateNotifierProvider<GyroNotifier, GyroData>((ref) => GyroNotifier());

class GyroData {
  GyroData({
    required this.x,
    required this.y,
    required this.z,
  });

  final double x;
  final double y;
  final double z;
}

class GyroNotifier extends StateNotifier<GyroData> {
  GyroNotifier() : super(GyroData(x: 0, y: 0, z: 0));

  void changeData(double x, double y, double z) {
    state = GyroData(x: x, y: y, z: z);
  }
}

class LogsNotifier extends StateNotifier<List<String>> {
  LogsNotifier() : super([]);

  void add(String message) {
    state = [
      ...state.getRange(max(state.length - 100, 0), state.length),
      message,
    ];
  }

  void clear() {
    state = [];
  }
}

class RunningStateNotifier extends StateNotifier<bool> {
  RunningStateNotifier() : super(false);

  void setRunningState(bool newState) {
    state = newState;
  }
}

final logsProvider = StateNotifierProvider<LogsNotifier, List<String>>((ref) {
  return LogsNotifier();
});

final isRunningProvider = StateNotifierProvider<RunningStateNotifier, bool>((ref) {
  return RunningStateNotifier();
});

final isConnectedProvider = StateProvider((ref) => false);
