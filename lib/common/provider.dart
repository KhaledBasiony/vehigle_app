import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class MessageNotifier extends Notifier<List<Message>> {
  @override
  List<Message> build() {
    return [];
  }

  void add(String message) {
    state = [
      ...state.getRange(max(state.length - 100, 0), state.length),
      Message(text: message),
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

final messagesProvider = NotifierProvider<MessageNotifier, List<Message>>(MessageNotifier.new);

final isRunningProvider = StateNotifierProvider<RunningStateNotifier, bool>((ref) {
  return RunningStateNotifier();
});

final isConnectedProvider = StateProvider((ref) => false);

final wheelAngleProvider = StateProvider<int>((ref) => 0);

class Message {
  Message({
    required this.text,
    DateTime? receivedAt,
  }) : receivedAt = receivedAt ?? DateTime.now();
  final String text;
  final DateTime receivedAt;
}
