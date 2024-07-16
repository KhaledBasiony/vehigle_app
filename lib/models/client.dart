import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:mobile_car_sim/common/db.dart';
import 'package:mobile_car_sim/pages/settings/mapper_model.dart';

typedef Uint8Callback = Function(Uint8List data);
typedef DynamicCallback = Function(dynamic data);

class Client {
  Client._({
    required Socket socket,
  }) : _socket = socket;

  static Client? _client;
  static Client get instance {
    if (!isConnected) {
      throw Exception('Must call connect before getting an instance');
    }
    return _client!;
  }

  static bool get isConnected => _client != null;

  final Socket _socket;
  bool _callbackRegistered = false;

  void addCallback(void Function(String text) callback) {
    if (_callbackRegistered) return;
    _socket.listen((event) {
      if (!(Db.instance.read<bool>(cExpectJson) ?? false)) {
        final mappers = List<Map>.from(Db.instance.read<List>(cBytesToJson) ?? []).map(
          (e) => BytesJsonMapperModel.fromJson(
            Map<String, dynamic>.from(e),
          ),
        );
        final bytes = event.buffer.asByteData();
        final jsonMessage = {};

        int byteOffset = 0;
        for (final mapper in mappers) {
          if (mapper.dataLengthType == DataLengthType.fixed) {
            switch (mapper.dataType) {
              case DataType.uint:
                jsonMessage[mapper.title] = switch (mapper.byteLength) {
                  1 => bytes.getUint8(byteOffset),
                  2 => bytes.getUint16(byteOffset),
                  4 => bytes.getUint32(byteOffset),
                  8 => bytes.getUint64(byteOffset),
                  _ => null,
                };
                break;
              case DataType.integer:
                jsonMessage[mapper.title] = switch (mapper.byteLength) {
                  1 => bytes.getInt8(byteOffset),
                  2 => bytes.getInt16(byteOffset),
                  4 => bytes.getInt32(byteOffset),
                  8 => bytes.getInt64(byteOffset),
                  _ => null,
                };
                break;
              case DataType.char:
                jsonMessage[mapper.title] = String.fromCharCode(bytes.getUint8(byteOffset));
                break;
              case DataType.float:
                jsonMessage[mapper.title] = switch (mapper.byteLength) {
                  4 => bytes.getFloat32(byteOffset),
                  8 => bytes.getFloat64(byteOffset),
                  _ => null,
                };
                break;
              default:
            }
            byteOffset += mapper.byteLength;
          }
        }
        return callback(jsonEncode(jsonMessage));
      } else {
        final text = utf8.decode(event);
        final lastReading = RegExp('.*({.*?})').firstMatch(text)?.group(1);
        return callback(lastReading ?? '');
      }
    });
    _callbackRegistered = true;
  }

  static Future<Client> connect(String ip, int port, [int? sourcePort]) async {
    if (_client != null) return _client!;
    final socket = await Socket.connect(
      ip,
      port,
    );
    return _client = Client._(socket: socket);
  }

  void send(List<int> command) {
    _socket.add(command);
  }

  void disconnect() async {
    _socket.destroy();
    _client = null;
    _callbackRegistered = false;
  }
}
