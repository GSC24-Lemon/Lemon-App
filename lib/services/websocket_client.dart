import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';

class WebsocketClient {
  IOWebSocketChannel? channel;

  WebsocketClient() {}

  void connect(
    String url,
    Map<String, String> headers,
  ) {
    if (channel != null && channel!.closeCode == null) {
      debugPrint('Already connected');
      return;
    }
    debugPrint('Connecting to the server...');
    channel = IOWebSocketChannel.connect(url,
        headers: headers); // buat konekin ke server websocket
  }

  void send(String data) {
    if (channel == null || channel!.closeCode != null) {
      debugPrint('Not connected');
      return;
    }
    channel!.sink.add(data);
  }

  void disconnect() {
    if (channel == null || channel!.closeCode != null) {
      debugPrint('Not connected');
      return;
    }
    channel!.sink.close();
  }
}
