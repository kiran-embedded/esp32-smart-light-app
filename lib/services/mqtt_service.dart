import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../core/constants/app_constants.dart';

class MqttService {
  MqttServerClient? _client;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  Future<bool> connect() async {
    try {
      _client = MqttServerClient.withPort(
        AppConstants.mqttBroker,
        AppConstants.mqttClientId,
        AppConstants.mqttPort,
      );

      _client!.logging(on: false);
      _client!.keepAlivePeriod = 20;
      _client!.onConnected = _onConnected;
      _client!.onDisconnected = _onDisconnected;
      _client!.onSubscribed = _onSubscribed;

      final connMessage = MqttConnectMessage()
          .withClientIdentifier(AppConstants.mqttClientId)
          .startClean()
          .withWillQos(MqttQos.atLeastOnce);

      _client!.connectionMessage = connMessage;

      await _client!.connect();
      _isConnected = true;
      return true;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }

  void _onConnected() {
    _isConnected = true;
  }

  void _onDisconnected() {
    _isConnected = false;
  }

  void _onSubscribed(String topic) {
    // Handle subscription
  }

  Future<void> publish(String topic, String message) async {
    if (!_isConnected || _client == null) return;

    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    _client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  void subscribe(String topic, Function(String) onMessage) {
    if (!_isConnected || _client == null) return;

    _client!.subscribe(topic, MqttQos.atLeastOnce);
    _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      final recMess = c![0].payload as MqttPublishMessage;
      final message = MqttPublishPayload.bytesToStringAsString(
        recMess.payload.message,
      );
      onMessage(message);
    });
  }

  void disconnect() {
    _client?.disconnect();
    _isConnected = false;
  }
}

