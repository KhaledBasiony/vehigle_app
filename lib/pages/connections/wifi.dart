import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_car_sim/common/provider.dart';
import 'package:mobile_car_sim/common/shortcuts/actions.dart';
import 'package:mobile_car_sim/common/theme.dart';
import 'package:mobile_car_sim/common/utils.dart';
import 'package:mobile_car_sim/common/widgets.dart';
import 'package:mobile_car_sim/models/client.dart';
import 'package:mobile_car_sim/models/simulator.dart';

class WifiDataCard extends ConsumerStatefulWidget {
  const WifiDataCard({super.key});

  @override
  ConsumerState<WifiDataCard> createState() => _WifiDataCardState();
}

class _WifiDataCardState extends ConsumerState<WifiDataCard> {
  TCPConnectionInfo? _tcpInfo;
  String? _status;

  late Future _waiter;

  @override
  void initState() {
    super.initState();
    _updateStatus();
    _waiter = _asyncInit();
  }

  void _updateStatus() => _status = Client.isConnected ? 'Connected' : 'Disconnected';

  Future<void> _asyncInit() async {
    _tcpInfo = await TCPConnectionInfo.detectInfo();
    if (_tcpInfo == null && mounted) {
      showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text('Warning!'),
          content: Text('Could not auto detect TCP Socket details over Wifi'),
        ),
      );
    }
  }

  void _refresh() async {
    if (Client.isConnected) Client.instance.disconnect();
    await MockServer.instance.down();
    ref.read(isConnectedProvider.notifier).state = false;
    setState(() {
      _updateStatus();
      _waiter = _asyncInit();
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
                        Text('Current Ip: ${_tcpInfo?.sourceIp}\n'
                            'Gateway Ip: ${_tcpInfo?.destinationIp}'),
                        Text('Connection:\n$_status'),
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
                      WifiConnectButton(
                        tcpInfo: _tcpInfo,
                        onDone: () => setState(() {
                          _updateStatus();
                        }),
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

class WifiConnectButton extends ConsumerWidget {
  const WifiConnectButton({
    super.key,
    this.onDone,
    this.tcpInfo,
    this.semiCircularButton = false,
  });

  final TCPConnectionInfo? tcpInfo;
  final VoidCallback? onDone;
  final bool semiCircularButton;

  void _connect(BuildContext context, WidgetRef ref) async {
    final info = tcpInfo ?? await TCPConnectionInfo.detectInfo();
    try {
      await Client.connect(info!.destinationIp, info.destinationPort);
      ref.read(isConnectedProvider.notifier).state = true;
      ref.read(isReceivingProvider.notifier).state = true;
      ref.read(wheelAngleProvider.notifier).state = 0;
      if (context.mounted) Actions.invoke(context, const SwitchReceivingIntent(true));
    } catch (e) {
      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Oops!'),
            content: Text(e.toString()),
          ),
        );
      }
    }

    if (onDone != null) onDone!();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (semiCircularButton) {
      return SemiCircularButton(
        roundAll: true,
        onPressed: Client.isConnected ? null : () => _connect(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Connect',
            style: TextStyle(
              fontSize: 32,
              color: Client.isConnected ? AppTheme.instance.theme.disabledColor : AppTheme.instance.primaryColor,
            ),
          ),
        ),
      );
    }
    return ElevatedButton(
      onPressed: Client.isConnected ? null : () => _connect(context, ref),
      child: const Text('Connect'),
    );
  }
}
