import 'dart:io';
import 'dart:async';
import 'dart:typed_data';

import 'package:network_info_plus/network_info_plus.dart';

const recievedDataMax = 128;

const defualtPortNum = 2300;
var defaultHandshake = SocketHandshake('MayIDr1ve', 'YesYouMay');

_returnNull(dynamic arg) => null;

class SocketHandshake {
  String send;
  String recv;

  SocketHandshake(this.send, this.recv);
}

class SocketResult {
  bool ok = true;
  SocketException? error;

  SocketResult(this.ok, [this.error]);
}

class ConnectSocket {
  Socket? _socket;
  bool _enabled = false;
  bool _verified = false;

  Future<SocketResult> connect(
      String ipAddress, int portNum, SocketHandshake handshake,
      {Function(SocketException) onError = _returnNull,
      Function onDisconnect = _returnNull,
      Function(List<int>) onRecieved = _returnNull}) async {
    try {
      _socket = await Socket.connect(ipAddress, portNum)
          .timeout(const Duration(seconds: 10));
    } on SocketException catch (error) {
      return SocketResult(false, error);
    }

    _socket?.write(handshake.send); // Send handshake
    await _socket?.flush();
    _socket?.listen(
      (List<int> data) async {
        if (_verified) {
          onRecieved(data);
        } else {
          var recv = String.fromCharCodes(data.where((e) => e != 0x0)).trim();
          if (recv == handshake.recv) {
            _verified = true;
          } else {
            onError(const SocketException('Handshake failed'));
            close();
          }
        }
      },
      onError: (error) async {
        onError(error);
        close();
      },
      onDone: () async {
        onDisconnect();
        close();
      },
    );

    _enabled = true;
    return SocketResult(true);
  }

  static Stream<String> scanNetwork(Function? progressCallback,
      [port = defualtPortNum]) async* {
    final String ip = await NetworkInfo().getWifiIP() ?? "";
    final String subnet = ip.substring(0, ip.lastIndexOf('.'));
    final StreamController<String> controller = StreamController();

    void addIP(String ip) {
      InternetAddress(ip)
          .reverse()
          .then((value) => value.host)
          .then((host) => controller.add(host))
          .catchError((_) => controller.add(ip));
    }

    int searched = 0;
    for (int i = 1; i < 256; i++) {
      final ip = '$subnet.$i';
      Socket.connect(ip, port, timeout: Duration(milliseconds: 500))
          .then((socket) {
        socket.close();
        addIP(ip);
      }).catchError((e) {
        if (e is SocketException && e.osError?.errorCode == 111) {
          addIP(ip);
        }
      }).whenComplete(() {
        progressCallback?.call(++searched / 255);
        if (searched >= 255) controller.close();
      });
    }

    yield* controller.stream;
  }

  Future<void> steerX(double x) async {
    ByteData bytes = ByteData(4);
    bytes.setFloat32(0, x);
    // print('Bytes x: ${bytes.buffer.asInt8List().toList()}');
    await _send('x'.codeUnits +
        [0, 0, 0] +
        bytes.buffer.asUint8List().reversed.toList());
  }

  Future<void> steerY(double y) async {
    ByteData bytes = ByteData(4);
    bytes.setFloat32(0, y);
    // print('Bytes Y: ${bytes.buffer.asInt8List().toList()}');
    await _send('y'.codeUnits +
        [0, 0, 0] +
        bytes.buffer.asUint8List().reversed.toList());
  }

  Future<void> motorSpeed(double s) async {
    ByteData bytes = ByteData(4);
    bytes.setFloat32(0, s);
    // print('Bytes M: ${bytes.buffer.asInt8List().toList()}');
    await _send('m'.codeUnits +
        [0, 0, 0] +
        bytes.buffer.asUint8List().reversed.toList());
  }

  Future<void> _send(List<int> data) async {
    if (!_verified || !_enabled) {
      return;
    }
    await _socket?.flush();
    _socket?.add(data);
  }

  Future<void> close() async {
    if (!_enabled) return;
    await _socket?.close();
    _verified = false;
    _enabled = false;
  }
}
