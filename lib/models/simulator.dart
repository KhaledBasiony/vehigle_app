import 'dart:io';

class MockServer {
  MockServer._({
    this.ip = '127.0.0.1',
    this.port = 4000,
  });

  static MockServer? _instance;

  factory MockServer.singleton() => _instance ??= MockServer._();

  Future<void> up() async {
    if (_socket != null) {
      print('Server already up');
      return;
    }
    _socket = await ServerSocket.bind(ip, port);
  }

  Future<void> down() async {
    await _socket?.close();
    _socket = null;
  }

  ServerSocket? _socket;
  final String ip;
  final int port;
}
