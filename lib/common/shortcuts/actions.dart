import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_car_sim/common/db.dart';
import 'package:mobile_car_sim/common/provider.dart';
import 'package:mobile_car_sim/models/client.dart';
import 'package:mobile_car_sim/models/simulator.dart';

part 'intents.dart';

class MoveForwardAction extends Action<MoveForwardIntent> {
  MoveForwardAction({required this.ref});

  final WidgetRef ref;

  @override
  Object? invoke(MoveForwardIntent intent) {
    final notifier = ref.read(encoderStepProvider.notifier);
    notifier.state = Db.instance.read<double>(maxEncoderReading) ?? 5;
    Client.instance.send(Db.instance.read<List<int>>(cForwardButton) ?? []);
    return null;
  }
}

class MoveBackwardsAction extends Action<MoveBackwardsIntent> {
  MoveBackwardsAction({required this.ref});

  final WidgetRef ref;

  @override
  Object? invoke(MoveBackwardsIntent intent) {
    final notifier = ref.read(encoderStepProvider.notifier);
    notifier.state = -(Db.instance.read<double>(maxEncoderReading) ?? 5);
    Client.instance.send(Db.instance.read<List<int>>(cBackwardsButton) ?? []);
    return null;
  }
}

class StopAction extends Action<StopIntent> {
  StopAction({required this.ref});

  final WidgetRef ref;

  @override
  Object? invoke(StopIntent intent) {
    ref.read(encoderStepProvider.notifier).state = 0;
    Client.instance.send(Db.instance.read<List<int>>(cBrakesButton) ?? []);
    return null;
  }
}

class TurnLeftAction extends Action<TurnLeftIntent> {
  TurnLeftAction({required this.ref});

  final WidgetRef ref;

  @override
  Object? invoke(TurnLeftIntent intent) {
    final angleNotifier = ref.read(wheelAngleProvider.notifier);
    final angleStep = Db.instance.read<int>(steeringAngleStep) ?? 1;
    angleNotifier.state = switch (intent.updateType) {
      UpdateType.increment => max(angleNotifier.state - angleStep, -40),
      UpdateType.set => max(intent.value!, -40),
    };
    Client.instance.send([angleNotifier.state + 41]);
    return null;
  }
}

class TurnRightAction extends Action<TurnRightIntent> {
  TurnRightAction({required this.ref});

  final WidgetRef ref;

  @override
  Object? invoke(TurnRightIntent intent) {
    final angleNotifier = ref.read(wheelAngleProvider.notifier);
    final angleStep = Db.instance.read<int>(steeringAngleStep) ?? 1;
    angleNotifier.state = switch (intent.updateType) {
      UpdateType.increment => min(angleNotifier.state + angleStep, 40),
      UpdateType.set => min(intent.value!, 40),
    };
    Client.instance.send([angleNotifier.state + 41]);
    return null;
  }
}

class NavigateAction extends Action<NavigateIntent> {
  NavigateAction();

  @override
  Object? invoke(NavigateIntent intent) {
    final command = Db.instance.read<List<int>>(cNavigateButton);
    if (command != null) Client.instance.send(command);
    MockServer.instance.carState.base = 0;

    return null;
  }
}

class ParkAction extends Action<ParkIntent> {
  ParkAction();

  @override
  Object? invoke(ParkIntent intent) {
    final command = Db.instance.read<List<int>>(cParkButton);
    if (command != null) Client.instance.send(command);
    MockServer.instance.carState.base = 1;

    return null;
  }
}

class DriveBackAction extends Action<DriveBackIntent> {
  DriveBackAction();

  @override
  Object? invoke(DriveBackIntent intent) {
    final command = Db.instance.read<List<int>>(cDriveBackButton);
    if (command != null) Client.instance.send(command);
    return null;
  }
}

class RecordAction extends Action<StartRecordingIntent> {
  RecordAction();

  @override
  Object? invoke(StartRecordingIntent intent) {
    final command = Db.instance.read<List<int>>(cRecordButton);
    if (command != null) Client.instance.send(command);
    return null;
  }
}

class ReplayAction extends Action<ReplayParkIntent> {
  ReplayAction();

  @override
  Object? invoke(ReplayParkIntent intent) {
    final command = Db.instance.read<List<int>>(cReplayButton);
    if (command != null) Client.instance.send(command);
    return null;
  }
}
