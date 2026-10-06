import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:platform_serial/platform_serial.dart';
import 'package:usb_serial/usb_serial.dart';

class UsbSerialAdapter implements SerialPortInterface {
  final UsbPort usbPort;
  final UsbDevice usbDevice;

  SerialConfig _config = const SerialConfig(portName: 'USB');
  bool _isOpen = false;

  final StreamController<Uint8List> _dataStreamController =
      StreamController<Uint8List>.broadcast();
  final StreamController<String> _textStreamController =
      StreamController<String>.broadcast();
  final StreamController<SerialError> _errorStreamController =
      StreamController<SerialError>.broadcast();

  StreamSubscription<Uint8List>? _usbSubscription;
  final List<int> _readBuffer = [];

  UsbSerialAdapter(this.usbDevice, this.usbPort);

  @override
  SerialConfig get config => _config;

  @override
  bool get isOpen => _isOpen;

  @override
  Stream<Uint8List> get dataStream => _dataStreamController.stream;

  @override
  Stream<String> get textStream => _textStreamController.stream;

  @override
  Stream<SerialError> get errorStream => _errorStreamController.stream;

  @override
  Future<void> open(SerialConfig config) async {
    _config = config;
    final opened = await usbPort.open();
    if (!opened) {
      throw SerialError(
        type: SerialErrorType.ioError,
        message: 'Failed to open USB port',
      );
    }

    await usbPort.setDTR(false);
    await usbPort.setRTS(false);
    await usbPort.setPortParameters(
      config.baudRate,
      UsbPort.DATABITS_8,
      UsbPort.STOPBITS_1,
      UsbPort.PARITY_NONE,
    );

    _isOpen = true;
    _usbSubscription = usbPort.inputStream?.listen(
      (data) {
        _dataStreamController.add(data);
        _textStreamController.add(utf8.decode(data, allowMalformed: true));
        _readBuffer.addAll(data);
      },
      onError: (e) {
        _errorStreamController.add(
          SerialError(
            type: SerialErrorType.ioError,
            message: e.toString(),
          ),
        );
      },
      onDone: () {
        _isOpen = false;
      },
    );
  }

  @override
  Future<void> close() async {
    await _usbSubscription?.cancel();
    await usbPort.close();
    _isOpen = false;
    _readBuffer.clear();
  }

  @override
  Future<int> write(Uint8List data, {Duration? timeout}) async {
    if (!_isOpen)
      throw SerialError(
        type: SerialErrorType.ioError,
        message: 'Port is closed',
      );
    await usbPort.write(data);
    return data.length;
  }

  @override
  Future<int> writeText(String data, {Duration? timeout}) async {
    return write(Uint8List.fromList(utf8.encode(data)), timeout: timeout);
  }

  @override
  Future<Uint8List> readSync({Duration? timeout}) async {
    // Platform serial's readSync typically reads whatever is in the buffer immediately.
    return _popBuffer();
  }

  @override
  Future<String> readTextSync({Duration? timeout}) async {
    final data = await readSync(timeout: timeout);
    return utf8.decode(data, allowMalformed: true);
  }

  @override
  Future<Uint8List> read(int length, {Duration? timeout}) async {
    final stopwatch = Stopwatch()..start();
    final waitLimit = timeout ?? const Duration(milliseconds: 500);

    while (_readBuffer.length < length) {
      if (stopwatch.elapsed > waitLimit) {
        throw SerialError(
          type: SerialErrorType.timeout,
          message: 'Read timeout',
        );
      }
      await Future.delayed(const Duration(milliseconds: 10));
    }

    final chunk = _readBuffer.sublist(0, length);
    _readBuffer.removeRange(0, length);
    return Uint8List.fromList(chunk);
  }

  @override
  Future<String> readUntil(String terminator, {Duration? timeout}) async {
    final stopwatch = Stopwatch()..start();
    final waitLimit = timeout ?? const Duration(milliseconds: 500);
    final termBytes = utf8.encode(terminator);

    while (true) {
      final index = _indexOfSublist(_readBuffer, termBytes);
      if (index != -1) {
        final length = index + termBytes.length;
        final chunk = _readBuffer.sublist(0, length);
        _readBuffer.removeRange(0, length);
        return utf8.decode(chunk, allowMalformed: true);
      }

      if (stopwatch.elapsed > waitLimit) {
        throw SerialError(
          type: SerialErrorType.timeout,
          message: 'Read until timeout',
        );
      }
      await Future.delayed(const Duration(milliseconds: 10));
    }
  }

  @override
  Future<void> flush() async {
    // usb_serial handles flushing internally on write.
  }

  @override
  Future<int> bytesAvailable() async {
    return _readBuffer.length;
  }

  @override
  Future<SerialControlSignals> getControlSignals() async {
    return const SerialControlSignals(
      dtr: false,
      rts: false,
      cts: false,
      dsr: false,
      dcd: false,
    );
  }

  @override
  Future<bool> getCts() async {
    return false;
  }

  @override
  Future<void> resetBuffers() async {
    _readBuffer.clear();
  }

  @override
  Future<void> setDtr(bool enabled) async {
    await usbPort.setDTR(enabled);
  }

  @override
  Future<void> setRts(bool enabled) async {
    await usbPort.setRTS(enabled);
  }

  Uint8List _popBuffer() {
    final copy = Uint8List.fromList(_readBuffer);
    _readBuffer.clear();
    return copy;
  }

  int _indexOfSublist(List<int> list, List<int> sublist) {
    if (sublist.isEmpty) return 0;
    if (sublist.length > list.length) return -1;
    for (int i = 0; i <= list.length - sublist.length; i++) {
      bool found = true;
      for (int j = 0; j < sublist.length; j++) {
        if (list[i + j] != sublist[j]) {
          found = false;
          break;
        }
      }
      if (found) return i;
    }
    return -1;
  }
}
