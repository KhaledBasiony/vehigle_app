import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

typedef Uint8Callback = Function(Uint8List data);
typedef DynamicCallback = Function(dynamic data);

class Client {
  Client._({
    required Socket socket,
  }) : _socket = socket;

  static Client? _client;

  static bool get isConnected => _client != null;

  final Socket _socket;

  void addCallback(void Function(String text) callback) {
    _socket.listen((event) {
      callback(utf8.decode(event));
    });
  }

  static Future<Client> connect(String ip, int port) async {
    if (_client != null) return _client!;
    final socket = await Socket.connect(ip, port, sourcePort: port);
    return _client = Client._(socket: socket);
  }

  factory Client.singleton() {
    if (!isConnected) {
      throw Exception('Must call connect before getting an instance');
    }
    return _client!;
  }

  void send(List<int> command) {
    _socket.add(command);
  }

  void disconnect() async {
    _socket.destroy();
    _client = null;
  }
}
