import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

class Db {
  Db._();

  static Db? _instance;
  static Db get instance => _instance!;

  static Future<void> open() async {
    if (_instance != null) return;

    _instance = Db._()
      .._hiveBox = await Hive.openBox(
        'Settings',
        path: await getApplicationSupportDirectory().then((value) => value.path),
      );

    _instance!._initiate();
  }

  void _initiate() {
    if (read(cForwardButton) == null) {
      write(cForwardButton, 'f'.codeUnits);
    }
    if (read(cBackwardsButton) == null) {
      write(cBackwardsButton, 'r'.codeUnits);
    }
    if (read(cBrakesButton) == null) {
      write(cBrakesButton, 'b'.codeUnits);
    }
  }

  T? read<T>(String key) {
    return _hiveBox!.get(key);
  }

  Future<void> write(String key, dynamic value) async {
    await _hiveBox!.put(key, value);
  }

  Future<void> dispose() async {
    await _hiveBox!.close();
    _instance = null;
  }

  Box? _hiveBox;
}

const holdDownDelayKey = 'HoldDownDelay';
const simulatorReadingsDelay = 'SimulatorDelay';
const useSimulator = 'UseSimulator';
const steeringAngleStep = 'SteeringAngleStep';
const maxEncoderReading = 'MaxEncoderReading';
const useLightTheme = 'UseLightTheme';
const useJoystick = 'UseJoyStick';
const textScaleFactor = 'TextScaleFactor';

const cForwardButton = 'ForwardButtonCommand';
const cBackwardsButton = 'BackwardsButtonCommand';
const cBrakesButton = 'BrakesButtonCommand';
const cNavigateButton = 'NavigateButtonCommand';
const cParkButton = 'ParkButtonCommand';
const cDriveBackButton = 'DriveBackButtonCommand';
const cRecordButton = 'RecordButtonCommand';
const cReplayButton = 'ReplayButtonCommand';
