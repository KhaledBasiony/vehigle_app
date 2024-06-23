import 'dart:async';
import 'dart:convert';
import 'dart:io';

class MockServer {
  MockServer._({
    this.ip = '127.0.0.1',
    this.port = 4000,
  });

  static MockServer? _instance;

  factory MockServer.singleton() => _instance ??= MockServer._();

  Future<void> up() async {
    _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
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
  }

  void _sendData() {
    clientSocket?.add(
      utf8.encode(jsonEncode({
        'CF': 0,
        'CB': 0,
        'LF': 0,
        'LB': 0,
        'LC': 0,
        'RF': 0,
        'RB': 0,
        'RC': 0,
        'ENC': encoder,
        'CMPS': 0,
        'PHS': carState,
        'ALG': 0,
        'PRM_A': 0,
        'PRM_B': 0,
        'PRM_C': 0,
        'PRM_D': 0,
      })),
    );
  }

  ServerSocket? _socket;
  Socket? clientSocket;
  late Timer _timer;
  final String ip;
  final int port;

  // Readings variables.
  int carState = 0;
  num encoder = 0;
}
