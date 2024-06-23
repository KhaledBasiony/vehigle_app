import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_car_sim/common/provider.dart';
import 'package:mobile_car_sim/models/client.dart';

part 'intents.dart';

class MoveForwardAction extends Action<MoveForwardIntent> {
  MoveForwardAction({required this.ref});

  final WidgetRef ref;

  @override
  Object? invoke(MoveForwardIntent intent) {
    ref.read(encoderStepProvider.notifier).state += 1;
    Client.singleton().send('f'.codeUnits);
    return null;
  }
}

class MoveBackwardsAction extends Action<MoveBackwardsIntent> {
  MoveBackwardsAction({required this.ref});

  final WidgetRef ref;

  @override
  Object? invoke(MoveBackwardsIntent intent) {
    ref.read(encoderStepProvider.notifier).state -= 1;
    Client.singleton().send('r'.codeUnits);
    return null;
  }
}

class StopAction extends Action<StopIntent> {
  StopAction({required this.ref});

  final WidgetRef ref;

  @override
  Object? invoke(StopIntent intent) {
    ref.read(encoderStepProvider.notifier).state = 0;
    Client.singleton().send('b'.codeUnits);
    return null;
  }
}

class TurnLeftAction extends Action<TurnLeftIntent> {
  TurnLeftAction({required this.ref});

  final WidgetRef ref;

  @override
  Object? invoke(TurnLeftIntent intent) {
    final angleNotifier = ref.read(wheelAngleProvider.notifier);
    angleNotifier.state = max(angleNotifier.state - 1, -40);
    Client.singleton().send([angleNotifier.state + 40]);
    return null;
  }
}

class TurnRightAction extends Action<TurnRightIntent> {
  TurnRightAction({required this.ref});

  final WidgetRef ref;

  @override
  Object? invoke(TurnRightIntent intent) {
    final angleNotifier = ref.read(wheelAngleProvider.notifier);
    angleNotifier.state = min(angleNotifier.state + 1, 40);
    Client.singleton().send([angleNotifier.state + 40]);
    return null;
  }
}
