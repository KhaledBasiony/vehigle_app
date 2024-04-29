import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_car_sim/common/provider.dart';
import 'package:mobile_car_sim/models/client.dart';
import 'package:network_info_plus/network_info_plus.dart';
// import 'package:wifi_info_plugin_plus/wifi_info_plugin_plus.dart';

class WifiDataCard extends ConsumerStatefulWidget {
  const WifiDataCard({super.key});

  @override
  ConsumerState<WifiDataCard> createState() => _WifiDataCardState();
}

class _WifiDataCardState extends ConsumerState<WifiDataCard> {
  String? _ip;
  String? _gateway;
  String? _status;
  static const port = 4000;

  late Future _waiter;

  @override
  void initState() {
    super.initState();
    _updateStatus();
    _waiter = _asyncInit();
  }

  void _updateStatus() => _status = Client.isConnected ? 'Connected' : 'Disconnected';

  Future<void> _asyncInit() async {
    if (Platform.isAndroid) {
      // final network = await WifiInfoPlugin.wifiDetails;

      // _ip = network?.ipAddress;
      // _gateway = network?.routerIp;
    } else {
      final network = NetworkInfo();

      _ip = await network.getWifiIP();
      _gateway = await network.getWifiGatewayIP();
    }
  }

  void _refresh() {
    if (Client.isConnected) Client.singleton().disconnect();
    ref.read(isConnectedProvider.notifier).state = false;
    setState(() {
      _updateStatus();
      _waiter = _asyncInit();
    });
  }

  void _connect() async {
    try {
      await Client.connect(_gateway!, port);
      ref.read(isConnectedProvider.notifier).state = true;
    } catch (e) {
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Oops!'),
            content: Text(e.toString()),
          ),
        );
      }
    }

    setState(() {
      _updateStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _waiter,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text('Current Ip: $_ip\n'
                            'Gateway Ip: $_gateway'),
                        Text('Connection: $_status'),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      TextButton(
                        onPressed: _refresh,
                        child: Text(
                          'Refresh',
                          style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: Client.isConnected ? null : _connect,
                        child: const Text('Connect'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }
}
