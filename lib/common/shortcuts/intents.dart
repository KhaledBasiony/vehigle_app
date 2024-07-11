part of 'actions.dart';

enum UpdateType { increment, set }

class MoveForwardIntent extends Intent {
  const MoveForwardIntent();
}

class MoveBackwardsIntent extends Intent {
  const MoveBackwardsIntent();
}

class TurnLeftIntent extends Intent {
  const TurnLeftIntent({this.value}) : updateType = value == null ? UpdateType.increment : UpdateType.set;

  final int? value;
  final UpdateType updateType;
}

class TurnRightIntent extends Intent {
  const TurnRightIntent({this.value}) : updateType = value == null ? UpdateType.increment : UpdateType.set;

  final int? value;
  final UpdateType updateType;
}

class StopIntent extends Intent {
  const StopIntent();
}

class NavigateIntent extends Intent {
  const NavigateIntent();
}

class ParkIntent extends Intent {
  const ParkIntent();
}

class DriveBackIntent extends Intent {
  const DriveBackIntent();
}

class StartRecordingIntent extends Intent {
  const StartRecordingIntent();
}

class ReplayParkIntent extends Intent {
  const ReplayParkIntent();
}
