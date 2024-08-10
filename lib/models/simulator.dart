import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mobile_car_sim/common/db.dart';
import 'package:mobile_car_sim/common/globals.dart';
import 'package:mobile_car_sim/common/utils.dart';
import 'package:mobile_car_sim/models/car.dart';
import 'package:mobile_car_sim/pages/settings/mapper_model.dart';

class MockServer {
  MockServer._({
    this.ip = '127.0.0.1',
    this.port = cServerPort,
  });

  static MockServer? _instance;
  static MockServer get instance => _instance ??= MockServer._();

  ServerSocket? _socket;
  Socket? clientSocket;
  Timer? _timer;
  final String ip;
  final int port;
  final rng = Random();

  bool get isUp => _socket != null;

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
  final location = _Reading<Offset>(base: Offset.zero);
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
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: Db.instance.read<int>(simulatorReadingsDelay) ?? 50), (timer) {
      _sendData();
    });
    if (isUp) {
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
    if (!isUp) {
      print('Mock Server is no Up, ignoring');
      return;
    }
    _timer?.cancel();
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
    final compassDiff = _encoderStep * tan(_steeringAngle * pi / 180) / CarModel.instance.axleToAxle;
    final compassValue = compass.value % 360;

    final Offset newOffset;
    if (compassDiff != 0) {
      newOffset = arcToOffset(
        _steeringAngle.isNegative ? -compassValue * pi / 180 : pi - compassValue * pi / 180,
        compassDiff,
        _encoderStep.toDouble(),
      );
    } else {
      // pi / 2 - theta; because compass value is measured from Pos-Y (Clockwise) and Offset measures from Pos-X (CCW)
      newOffset = Offset.fromDirection(pi / 2 - compassValue * pi / 180, _encoderStep.toDouble());
    }
    final List<int> messageBytes;
    if (Db.instance.read<bool>(cExpectJson) ?? false) {
      messageBytes = utf8.encode(jsonEncode({
        'CF': cf.value,
        'CB': cb.value,
        'LF': lf.value,
        'LB': lb.value,
        'LC': lc.value,
        'RF': rf.value,
        'RB': rb.value,
        'RC': rc.value,
        'ENC': encoder.value,
        'dX': newOffset.dx,
        'dY': newOffset.dy,
        'CMPS': compassValue,
        'PHS': carState.value,
        'ALG': algorithm.value,
        'PRM_A': paramA.value,
        'PRM_B': paramB.value,
        'PRM_C': paramC.value,
        'PRM_D': paramD.value,
      }));
    } else {
      messageBytes = [
        ..._getBytes(cf.value, DataType.float, 8),
        ..._getBytes(cb.value, DataType.float, 8),
        ..._getBytes(lf.value, DataType.float, 8),
        ..._getBytes(lb.value, DataType.float, 8),
        ..._getBytes(lc.value, DataType.float, 8),
        ..._getBytes(rf.value, DataType.float, 8),
        ..._getBytes(rb.value, DataType.float, 8),
        ..._getBytes(rc.value, DataType.float, 8),
        ..._getBytes(encoder.value, DataType.float, 8),
        ..._getBytes(newOffset.dx, DataType.float, 8),
        ..._getBytes(newOffset.dy, DataType.float, 8),
        ..._getBytes(compassValue, DataType.float, 8),
        ..._getBytes(carState.value, DataType.float, 8),
        ..._getBytes(algorithm.value, DataType.float, 8),
        ..._getBytes(paramA.value, DataType.float, 8),
        ..._getBytes(paramB.value, DataType.float, 8),
        ..._getBytes(paramC.value, DataType.float, 8),
        ..._getBytes(paramD.value, DataType.float, 8),
      ];
    }
    clientSocket?.add(messageBytes);
    cf.oneTime = (rng.nextDouble() * 0.5 + 0.25) * CarModel.maxReading;
    cb.oneTime = (rng.nextDouble() * 0.5 + 0.25) * CarModel.maxReading;
    lc.oneTime = (rng.nextDouble() * 0.5 + 0.25) * CarModel.maxReading;
    rc.oneTime = (rng.nextDouble() * 0.5 + 0.25) * CarModel.maxReading;
    lf.oneTime = 0.0;
    rf.oneTime = 0.0;
    lb.oneTime = 0.0;
    rb.oneTime = 0.0;

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
    _steeringAngle = angle - 41;
  }

  _moveForward() {
    _encoderStep = Db.instance.read<double>(maxEncoderReading) ?? 5;
  }

  _brakes() {
    _encoderStep = 0;
  }

  _moveBackwards() {
    _encoderStep = -(Db.instance.read<double>(maxEncoderReading) ?? 5);
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

List<int> _getBytes(num value, DataType type, int length) {
  final bytes = ByteData(length);
  switch (type) {
    case DataType.uint:
      switch (length) {
        case 1:
          bytes.setUint8(0, value as int);
          break;
        case 2:
          bytes.setUint16(0, value as int);
          break;
        case 4:
          bytes.setUint32(0, value as int);
          break;
        case 8:
          bytes.setUint64(0, value as int);
          break;
        default:
          break;
      }

      break;
    case DataType.integer:
      switch (length) {
        case 1:
          bytes.setInt8(0, value as int);
          break;
        case 2:
          bytes.setInt16(0, value as int);
          break;
        case 4:
          bytes.setInt32(0, value as int);
          break;
        case 8:
          bytes.setInt64(0, value as int);
          break;
        default:
          break;
      }
      break;
    case DataType.char:
      bytes.setUint8(0, value as int);
      break;
    case DataType.float:
      switch (length) {
        case 4:
          bytes.setFloat32(0, value.toDouble());
          break;
        case 8:
          bytes.setFloat64(0, value.toDouble());
          break;
        default:
          break;
      }
      break;
    default:
  }
  return bytes.buffer.asUint8List().toList();
}
