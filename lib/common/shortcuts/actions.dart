import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_car_sim/common/db.dart';
import 'package:mobile_car_sim/common/provider.dart';
import 'package:mobile_car_sim/models/client.dart';

part 'intents.dart';

class MoveForwardAction extends Action<MoveForwardIntent> {
  MoveForwardAction({required this.ref});

  final WidgetRef ref;

  @override
  Object? invoke(MoveForwardIntent intent) {
    ref.read(encoderStepProvider.notifier).state += 1;
    Client.instance.send('f'.codeUnits);
    return null;
  }
}

class MoveBackwardsAction extends Action<MoveBackwardsIntent> {
  MoveBackwardsAction({required this.ref});

  final WidgetRef ref;

  @override
  Object? invoke(MoveBackwardsIntent intent) {
    ref.read(encoderStepProvider.notifier).state -= 1;
    Client.instance.send('r'.codeUnits);
    return null;
  }
}

class StopAction extends Action<StopIntent> {
  StopAction({required this.ref});

  final WidgetRef ref;

  @override
  Object? invoke(StopIntent intent) {
    ref.read(encoderStepProvider.notifier).state = 0;
    Client.instance.send('b'.codeUnits);
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
    angleNotifier.state = max(angleNotifier.state - angleStep, -40);
    Client.instance.send([angleNotifier.state + 40]);
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
    angleNotifier.state = min(angleNotifier.state + angleStep, 40);
    Client.instance.send([angleNotifier.state + 40]);
    return null;
  }
}
