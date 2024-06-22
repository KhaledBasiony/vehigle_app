import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class CarStateNotifier extends Notifier<CarStates> {
  @override
  CarStates build() {
    return CarStates.searching;
  }

  void update(CarStates newValue) => state = newValue;
}

enum CarStates {
  searching('Searching..'),
  waitingAlgoSelection('Waiting Algo Selection!'),
  parking('Parking');

  const CarStates(this.disp);

  final String disp;
}

final carStatesProvider = NotifierProvider<CarStateNotifier, CarStates>(CarStateNotifier.new);

final logsProvider = StateNotifierProvider<LogsNotifier, List<String>>((ref) {
  return LogsNotifier();
});

final isRunningProvider = StateNotifierProvider<RunningStateNotifier, bool>((ref) {
  return RunningStateNotifier();
});

final isConnectedProvider = StateProvider((ref) => false);
