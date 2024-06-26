import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:mobile_car_sim/common/db.dart';
import 'package:mobile_car_sim/models/car.dart';

class MockServer {
  MockServer._({
    this.ip = '127.0.0.1',
    this.port = 4000,
  });

  static MockServer? _instance;
  static MockServer get instance => _instance ??= MockServer._();

  ServerSocket? _socket;
  Socket? clientSocket;
  late Timer _timer;
  final String ip;
  final int port;
  final rng = Random();

  // Readings variables.
  final cf = _Reading<num>(base: 0);
  final cb = _Reading<num>(base: 0);
  final lf = _Reading<num>(base: 0);
  final lb = _Reading<num>(base: 0);
  final lc = _Reading<num>(base: 0);
  final rf = _Reading<num>(base: 0);
  final rb = _Reading<num>(base: 0);
  final rc = _Reading<num>(base: 0);
  final encoder = _Reading<num>(base: 0);
  final compass = _Reading<num>(base: 0);
  final carState = _Reading<int>(base: 0);
  final phase = _Reading<int>(base: 0);
  final algorithm = _Reading<int>(base: 0);
  final paramA = _Reading<int>(base: 0);
  final paramB = _Reading<int>(base: 0);
  final paramC = _Reading<int>(base: 0);
  final paramD = _Reading<int>(base: 0);

  num _steeringAngle = 0;
  num _encoderStep = 0;

  Future<void> up() async {
    _timer = Timer.periodic(Duration(milliseconds: Db.instance.read<int>(simulatorReadingsDelay) ?? 50), (timer) {
      _sendData();
    });
    if (_socket != null) {
      print('Mock Server already up');
      return;
    }
    _socket = await ServerSocket.bind(ip, port, shared: true);

    _socket?.listen(
      (event) async {
        clientSocket = event;
        clientSocket!.listen((event) {
          print('Received: ${utf8.decode(event)}');
          handleCommand(event);
        });
      },
      cancelOnError: true,
    );
  }

  Future<void> down() async {
    _timer.cancel();
    clientSocket?.destroy();
    await _socket?.close();
    clientSocket = null;
    _socket = null;

    // Reset readings
    // Readings variables.
    cf._base = 0;
    cb._base = 0;
    lf._base = 0;
    lb._base = 0;
    lc._base = 0;
    rf._base = 0;
    rb._base = 0;
    rc._base = 0;
    encoder._base = 0;
    compass._base = 0;
    carState._base = 0;
    phase._base = 0;
    algorithm._base = 0;
    paramA._base = 0;
    paramB._base = 0;
    paramC._base = 0;
    paramD._base = 0;

    _steeringAngle = 0;
    _encoderStep = 0;
  }

  void _sendData() {
    clientSocket?.add(
      utf8.encode(jsonEncode({
        'CF': cf.value,
        'CB': cb.value,
        'LF': lf.value,
        'LB': lb.value,
        'LC': lc.value,
        'RF': rf.value,
        'RB': rb.value,
        'RC': rc.value,
        'ENC': encoder.value,
        'CMPS': compass.value % 360,
        'PHS': carState.value,
        'ALG': algorithm.value,
        'PRM_A': paramA.value,
        'PRM_B': paramB.value,
        'PRM_C': paramC.value,
        'PRM_D': paramD.value,
      })),
    );
    cf.oneTime = rng.nextDouble() * 0.5 + 0.25;
    cb.oneTime = rng.nextDouble() * 0.5 + 0.25;
    lc.oneTime = rng.nextDouble() * 0.5 + 0.25;
    rc.oneTime = rng.nextDouble() * 0.5 + 0.25;
    lf.oneTime = 0.0;
    rf.oneTime = 0.0;
    lb.oneTime = 0.0;
    rb.oneTime = 0.0;

    final compassDiff = _encoderStep * tan(_steeringAngle * pi / 180) / CarModel.instance.axleToAxle;
    compass.base = compass._base + compassDiff * 180 / pi;
    encoder.base = encoder._base + _encoderStep;
  }

  void handleCommand(List<int> command) {
    // expected to be only one byte in command.
    for (final byte in command) {
      final _ = switch (byte) {
        >= 0 && <= 80 => _steer(byte),
        == 0x0066 /* f */ => _moveForward(),
        == 0x0062 /* b */ => _brakes(),
        == 0x0072 /* r */ => _moveBackwards(),
        _ => null,
      };
    }
  }

  set encoderStep(num step) => _encoderStep = step;

  void _steer(int angle) {
    // WARNING: this is not realistic, in reality this should change the wheels steering angles
    // but for simulation purposes it will change the compass angle
    _steeringAngle = angle - 40;
  }

  _moveForward() {
    _encoderStep += 1;
  }

  _brakes() {
    _encoderStep = 0;
  }

  _moveBackwards() {
    _encoderStep -= 1;
  }
}

class _Reading<T> {
  _Reading({
    required T base,
    T? oneTime,
  })  : _base = base,
        _oneTime = oneTime;

  T? _oneTime;
  T _base;

  set oneTime(T? value) => _oneTime = value;
  set base(T value) => _base = value;

  T get value {
    final ret = _oneTime ?? _base;
    oneTime = null;
    return ret;
  }
}
