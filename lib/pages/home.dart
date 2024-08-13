import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_car_sim/common/globals.dart';
import 'package:mobile_car_sim/common/provider.dart';
import 'package:mobile_car_sim/common/shortcuts/actions.dart';
import 'package:mobile_car_sim/models/client.dart';
import 'package:mobile_car_sim/models/simulator.dart';
import 'package:mobile_car_sim/pages/client/fullscreen_controls.dart';
import 'package:mobile_car_sim/pages/client/receiver.dart';
import 'package:mobile_car_sim/pages/client/controls.dart';
import 'package:mobile_car_sim/pages/connections/wifi.dart';
import 'package:mobile_car_sim/pages/drawing/drawing.dart';
import 'package:mobile_car_sim/pages/settings/drawer.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key, this.isUser = false});

  final bool isUser;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with SingleTickerProviderStateMixin {
  static const shortcutActivators = {
    SingleActivator(LogicalKeyboardKey.arrowUp, shift: true): MoveForwardIntent(),
    SingleActivator(LogicalKeyboardKey.arrowDown, shift: true): MoveBackwardsIntent(),
    SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true): TurnLeftIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight, shift: true): TurnRightIntent(),
    SingleActivator(LogicalKeyboardKey.space, shift: true): StopIntent(),
  };

  static const mapTag = 'Map';
  static const mapKey = ValueKey(mapTag);
  int _tabInitIndex = 0;

  void _killConnection([bool force = false]) async {
    if (force || !kDebugMode) {
      if (Client.isConnected) Client.instance.disconnect();
      await MockServer.instance.down();
      ref.read(isConnectedProvider.notifier).state = false;
      ref.read(isFullScreenProvider.notifier).state = false;
    }
  }

  void _logout() {
    _killConnection(true);
    Navigator.popAndPushNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    AppLifecycleListener(
      onInactive: () => _killConnection(),
    );

    const settingsDrawer = Drawer(
      width: 500,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 8.0),
        child: SettingsEditor(),
      ),
    );

    final logoutButton = IconButton(
      onPressed: _logout,
      icon: const Icon(Icons.logout_rounded),
    );

    final appBar = AppBar(
      title: const Text('Vehigle Sim'),
      centerTitle: true,
      leading: Builder(builder: (context) {
        return IconButton(
          onPressed: Scaffold.of(context).openDrawer,
          icon: const Icon(
            Icons.settings_rounded,
          ),
        );
      }),
      actions: [logoutButton],
    );

    final actions = <Type, Action<Intent>>{
      MoveForwardIntent: MoveForwardAction(ref: ref),
      MoveBackwardsIntent: MoveBackwardsAction(ref: ref),
      TurnLeftIntent: TurnLeftAction(ref: ref),
      TurnRightIntent: TurnRightAction(ref: ref),
      StopIntent: StopAction(ref: ref),
      AccelerateIntent: AccelerateAction(ref: ref),
      DecelerateIntent: DecelerateAction(ref: ref),
      NavigateIntent: NavigateAction(),
      ParkIntent: ParkAction(),
      DriveBackIntent: DriveBackAction(ref: ref),
      StartRecordingIntent: RecordAction(ref: ref),
      ReplayParkIntent: ReplayAction(),
      SwitchReceivingIntent: SwitchReceivingAction(ref: ref),
    };

    final tabSwitcher = TabBar(
      onTap: (value) => _tabInitIndex = value,
      tabs: const [
        Tab(text: 'Client'),
        Tab(text: 'Map'),
      ],
    );

    const tabView = TabBarView(
      children: [
        _ClientWidget(),
        Stack(
          children: [
            MapCanvas(key: mapKey),
            Positioned(
              top: 0,
              right: 0,
              child: FullScreenSwitcher(),
            ),
          ],
        ),
      ],
    );

    final userBody = Center(
      child: IntrinsicHeight(
        child: IntrinsicWidth(
          child: WifiConnectButton(
            semiCircularButton: true,
            onDone: () => ref.read(isFullScreenProvider.notifier).state = true,
          ),
        ),
      ),
    );

    final developerBody = DefaultTabController(
      initialIndex: _tabInitIndex,
      length: 2,
      child: FocusScope(
        autofocus: true,
        child: Column(
          key: const ValueKey('NormalBody'),
          children: [
            tabSwitcher,
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isVertical = constraints.maxWidth < 1000;
                  final controlConstraints = isVertical
                      ? BoxConstraints(maxHeight: constraints.maxHeight / 2)
                      : BoxConstraints(maxWidth: constraints.maxWidth / 2);

                  final controlsArea = ConstrainedBox(
                    constraints: controlConstraints,
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: ControlsCard(),
                    ),
                  );

                  return Flex(
                    direction: isVertical ? Axis.vertical : Axis.horizontal,
                    children: [
                      const Expanded(child: tabView),
                      controlsArea,
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    final isControlsView = ref.watch(isControlsViewProvider);
    final controlsViewSwitcher = IconButton(
      onPressed: () {
        ref.read(isControlsViewProvider.notifier).state ^= true;
      },
      icon: isControlsView ? const Icon(Icons.map_rounded) : const Icon(Icons.grid_on_rounded),
    );
    final fullScreenBody = Stack(
      key: const ValueKey('FullScreenBody'),
      children: [
        AnimatedSwitcher(
          duration: Durations.short4,
          child: isControlsView ? const Center(child: ReadingsSetter()) : const MapCanvas(key: mapKey),
        ),
        Positioned(
          top: 0,
          left: 0,
          child: controlsViewSwitcher,
        ),
        const Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: DrDriverControls(),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: widget.isUser ? logoutButton : const FullScreenSwitcher(),
        ),
      ],
    );

    final isFullScreen = ref.watch(isFullScreenProvider);

    return Actions(
      actions: actions,
      child: PageStorage(
        bucket: cPageBucket,
        child: Shortcuts(
          shortcuts: shortcutActivators,
          child: SafeArea(
            child: Scaffold(
              drawer: const Padding(
                padding: EdgeInsetsDirectional.only(end: 50.0),
                child: settingsDrawer,
              ),
              appBar: isFullScreen ? null : appBar,
              body: isFullScreen
                  ? fullScreenBody
                  : widget.isUser
                      ? userBody
                      : developerBody,
            ),
          ),
        ),
      ),
    );
  }
}

class FullScreenSwitcher extends ConsumerWidget {
  const FullScreenSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: IconButton.filledTonal(
        iconSize: 30,
        tooltip: 'Toggle Fullscreen',
        onPressed: () => ref.read(isFullScreenProvider.notifier).state ^= true,
        icon: AnimatedSwitcher(
          duration: Durations.medium2,
          child: ref.watch(isFullScreenProvider)
              ? const Icon(
                  key: ValueKey('FullScreen-Off'),
                  Icons.fullscreen_exit_rounded,
                )
              : const Icon(
                  key: ValueKey('FullScreen-On'),
                  Icons.fullscreen_rounded,
                ),
        ),
      ),
    );
  }
}

class _ClientWidget extends StatelessWidget {
  const _ClientWidget();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: WifiDataCard(),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: ValueWatcher(),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: MessageLogger(),
          ),
        ],
      ),
    );
  }
}
