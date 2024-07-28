import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_car_sim/common/db.dart';
import 'package:mobile_car_sim/common/provider.dart';
import 'package:mobile_car_sim/common/shortcuts/actions.dart';
import 'package:mobile_car_sim/common/theme.dart';
import 'package:mobile_car_sim/common/utils.dart';
import 'package:mobile_car_sim/pages/client/receiver.dart';
import 'package:mobile_car_sim/pages/client/controls.dart';
import 'package:mobile_car_sim/pages/connections/wifi.dart';
import 'package:mobile_car_sim/pages/drawing/drawing.dart';
import 'package:mobile_car_sim/pages/settings/drawer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Db.open();
  runApp(const ExampleApplication());
}

class ExampleApplication extends StatelessWidget {
  const ExampleApplication({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        builder: (context, child) {
          final MediaQueryData data = MediaQuery.of(context);
          return MediaQuery(
            data: data.copyWith(textScaler: TextScaler.linear(Db.instance.read<double>(textScaleFactor) ?? 1.0)),
            child: child!,
          );
        },
        theme: AppTheme.instance.theme,
        home: const MainPage(),
      ),
    );
  }
}

class MainPage extends ConsumerWidget {
  const MainPage({super.key});

  static const shortcutActivators = {
    SingleActivator(LogicalKeyboardKey.arrowUp, shift: true): MoveForwardIntent(),
    SingleActivator(LogicalKeyboardKey.arrowDown, shift: true): MoveBackwardsIntent(),
    SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true): TurnLeftIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight, shift: true): TurnRightIntent(),
    SingleActivator(LogicalKeyboardKey.space, shift: true): StopIntent(),
  };

  static const mapTag = 'Map';
  static const mapKey = ValueKey(mapTag);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const settingsDrawer = Drawer(
      width: 500,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 8.0),
        child: SettingsEditor(),
      ),
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
    );

    final actions = <Type, Action<Intent>>{
      MoveForwardIntent: MoveForwardAction(ref: ref),
      MoveBackwardsIntent: MoveBackwardsAction(ref: ref),
      TurnLeftIntent: TurnLeftAction(ref: ref),
      TurnRightIntent: TurnRightAction(ref: ref),
      StopIntent: StopAction(ref: ref),
      NavigateIntent: NavigateAction(),
      ParkIntent: ParkAction(),
      DriveBackIntent: DriveBackAction(),
      StartRecordingIntent: RecordAction(),
      ReplayParkIntent: ReplayAction(),
      SwitchReceivingIntent: SwitchReceivingAction(ref: ref),
    };

    const tabSwitcher = TabBar(
      tabs: [
        Tab(text: 'Client'),
        Tab(text: 'Map'),
      ],
    );

    const tabView = TabBarView(
      children: [
        _ClientWidget(),
        MapCanvas(key: mapKey),
      ],
    );

    final normalBody = Column(
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
                  child: FocusScope(
                    autofocus: true,
                    child: ControlsCard(),
                  ),
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
    );

    const fullScreenBody = Stack(
      key: ValueKey('FullScreenBody'),
      children: [
        MapCanvas(
          key: mapKey,
        ),
      ],
    );

    final isFullScreen = ref.watch(isFullScreenProvider);

    return Actions(
      actions: actions,
      child: PageStorage(
        bucket: pageBucket,
        child: Shortcuts(
          shortcuts: shortcutActivators,
          child: SafeArea(
            child: Scaffold(
              drawer: const Padding(
                padding: EdgeInsetsDirectional.only(end: 50.0),
                child: settingsDrawer,
              ),
              appBar: isFullScreen ? null : appBar,
              body: DefaultTabController(
                length: 2,
                child: AnimatedSwitcher(
                  duration: Durations.long4,
                  switchInCurve: Curves.easeInOutCubic,
                  switchOutCurve: Curves.easeInOutCubic,
                  child: isFullScreen ? fullScreenBody : normalBody,
                ),
              ),
            ),
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
