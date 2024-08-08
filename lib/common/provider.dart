import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class Message {
  Message({
    required this.text,
    DateTime? receivedAt,
  }) : receivedAt = receivedAt ?? DateTime.now();
  final String text;
  final DateTime receivedAt;
}

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

enum CarNavigationState {
  searching('Searching..'),
  waitingAlgoSelection('Waiting Algo Selection!'),
  parking('Parking');

  const CarNavigationState(this.disp);

  final String disp;
}

enum CarRecordingState {
  notRecording,
  recording,
}

enum CarDriveBackState {
  driving,
  waiting,
}

final messagesProvider = NotifierProvider<MessageNotifier, List<Message>>(MessageNotifier.new);

final navigationStateProvider = StateProvider<CarNavigationState>((ref) => CarNavigationState.searching);
final recordingStateProvider = StateProvider<CarRecordingState>((ref) => CarRecordingState.notRecording);
final driveBackProvider = StateProvider<CarDriveBackState>((ref) => CarDriveBackState.waiting);

final isConnectedProvider = StateProvider((ref) => false);
final isReceivingProvider = StateProvider((ref) => true);

final wheelAngleProvider = StateProvider<int>((ref) => 0);
final encoderStepProvider = StateProvider<num>((ref) => 0.0);

final isFullScreenProvider = StateProvider<bool>((ref) => false);
final isControlsViewProvider = StateProvider<bool>((ref) => false);
