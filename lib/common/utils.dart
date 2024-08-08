import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mobile_car_sim/common/db.dart';
import 'package:mobile_car_sim/common/globals.dart';
import 'package:mobile_car_sim/models/simulator.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:wifi_info_plugin_plus/wifi_info_plugin_plus.dart';

Offset arcToOffset(double thetaStart, double thetaDelta, double distance) {
  final thetaEnd = thetaStart + thetaDelta;
  if (thetaDelta != 0) {
    final r = distance.abs() / thetaDelta.abs();
    var offset = Offset(
      r * (cos(thetaStart) - cos(thetaEnd)),
      r * (sin(thetaStart) - sin(thetaEnd)),
    );
    return offset;
  } else {
    throw ArgumentError.value(thetaEnd);
  }
}

class TCPConnectionInfo {
  TCPConnectionInfo._({
    required this.sourceIp,
    required this.destinationIp,
    required this.destinationPort,
  });

  static Future<TCPConnectionInfo?> detectInfo() async {
    final useSim = Db.instance.read<bool>(useSimulator);
    if (useSim ?? false) {
      await MockServer.instance.up();
      return TCPConnectionInfo._(
        sourceIp: MockServer.instance.ip,
        destinationIp: MockServer.instance.ip,
        destinationPort: MockServer.instance.port,
      );
    }
    if (Platform.isAndroid) {
      final network = await WifiInfoPlugin.wifiDetails;

      if (network == null) {
        return null;
      }
      return TCPConnectionInfo._(
        sourceIp: network.ipAddress,
        destinationIp: network.routerIp,
        destinationPort: cServerPort,
      );
    } else {
      final network = NetworkInfo();

      final ip = await network.getWifiIP();
      final gateway = await network.getWifiGatewayIP();
      if (ip == null || gateway == null) {
        return null;
      }

      return TCPConnectionInfo._(
        sourceIp: ip,
        destinationIp: gateway,
        destinationPort: cServerPort,
      );
    }
  }

  final String? sourceIp;
  final String destinationIp;
  final int destinationPort;
}
