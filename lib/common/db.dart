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
      write(cBackwardsButton, 'b'.codeUnits);
    }
    if (read(cBrakesButton) == null) {
      write(cBrakesButton, 's'.codeUnits);
    }
    if (read(cAccelerateButton) == null) {
      write(cAccelerateButton, 'n'.codeUnits);
    }
    if (read(cDecelerateButton) == null) {
      write(cDecelerateButton, 'm'.codeUnits);
    }
    if (read(cNavigateButton) == null) {
      write(cNavigateButton, 'v'.codeUnits);
    }
    if (read(cParallelButton) == null) {
      write(cParallelButton, 'w'.codeUnits);
    }
    if (read(cPerpendicularButton) == null) {
      write(cPerpendicularButton, 'q'.codeUnits);
    }
    if (read(cDriveBackButton) == null) {
      write(cDriveBackButton, 'd'.codeUnits);
    }
    if (read(cRecordButton) == null) {
      write(cRecordButton, 'r'.codeUnits);
    }
    if (read(cReplayButton) == null) {
      write(cReplayButton, 'a'.codeUnits);
    }
    if (read(steeringAngleStep) == null) {
      write(steeringAngleStep, 5);
    }
    if (read(useJoystick) == null) {
      write(useJoystick, false);
    }
    if (read(cExpectJson) == null) {
      write(cExpectJson, true);
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
const maxSensorHistory = 'MaxSensorHistory';
const shouldFadeHistory = 'ShouldFadeHistory';
const maxSensorsReading = 'MaxSensorReading';
const useLightTheme = 'UseLightTheme';
const useJoystick = 'UseJoyStick';
const textScaleFactor = 'TextScaleFactor';

const cForwardButton = 'ForwardButtonCommand';
const cBackwardsButton = 'BackwardsButtonCommand';
const cBrakesButton = 'BrakesButtonCommand';
const cAccelerateButton = 'AccelerateButtonCommand';
const cDecelerateButton = 'DecelerateButtonCommand';
const cNavigateButton = 'NavigateButtonCommand';
const cParallelButton = 'ParallelButtonCommand';
const cPerpendicularButton = 'PerpendicularButtonCommand';
const cDriveBackButton = 'DriveBackButtonCommand';
const cRecordButton = 'RecordButtonCommand';
const cReplayButton = 'ReplayButtonCommand';

const cExpectJson = 'ExpectJson';
const cBytesToJson = 'BytesToJson';
const endDelimiterCharacter = 'EndDelimiterCharacter';
