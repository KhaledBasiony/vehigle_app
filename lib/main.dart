import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_car_sim/common/db.dart';
import 'package:mobile_car_sim/common/shortcuts/actions.dart';
import 'package:mobile_car_sim/pages/client/receiver.dart';
import 'package:mobile_car_sim/pages/client/controls.dart';
import 'package:mobile_car_sim/pages/connections/wifi.dart';
import 'package:mobile_car_sim/pages/drawing/drawing.dart';
import 'package:mobile_car_sim/pages/settings.dart';

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
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            brightness: Brightness.dark,
            seedColor: Colors.blueAccent,
          ),
        ),
        home: const MainPage(),
      ),
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) => Actions(
        actions: {
          MoveForwardIntent: MoveForwardAction(ref: ref),
          MoveBackwardsIntent: MoveBackwardsAction(ref: ref),
          TurnLeftIntent: TurnLeftAction(ref: ref),
          TurnRightIntent: TurnRightAction(ref: ref),
          StopIntent: StopAction(ref: ref),
        },
        child: child!,
      ),
      child: SafeArea(
        child: Scaffold(
          drawer: const Padding(
            padding: EdgeInsetsDirectional.only(end: 50.0),
            child: Drawer(
              width: 500,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 8.0),
                child: SettingsEditor(),
              ),
            ),
          ),
          appBar: AppBar(
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
          ),
          body: Shortcuts(
            shortcuts: const {
              SingleActivator(LogicalKeyboardKey.arrowUp, shift: true): MoveForwardIntent(),
              SingleActivator(LogicalKeyboardKey.arrowDown, shift: true): MoveBackwardsIntent(),
              SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true): TurnLeftIntent(),
              SingleActivator(LogicalKeyboardKey.arrowRight, shift: true): TurnRightIntent(),
              SingleActivator(LogicalKeyboardKey.space, shift: true): StopIntent(),
            },
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Client'),
                      Tab(text: 'Map'),
                    ],
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isVertical = constraints.maxWidth < 1000;
                        final controlConstraints = isVertical
                            ? BoxConstraints(maxHeight: constraints.maxHeight / 2)
                            : BoxConstraints(maxWidth: constraints.maxWidth / 2);
                        return Flex(
                          direction: isVertical ? Axis.vertical : Axis.horizontal,
                          children: [
                            const Expanded(
                              child: TabBarView(
                                children: [
                                  _ClientWidget(),
                                  MapCanvas(),
                                ],
                              ),
                            ),
                            ConstrainedBox(
                              constraints: controlConstraints,
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: FocusScope(
                                  autofocus: true,
                                  child: ControlsCard(),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
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
            child: ReceiverCard(),
          ),
        ],
      ),
    );
  }
}
