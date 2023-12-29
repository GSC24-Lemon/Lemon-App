import 'dart:convert';

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
        headers: headers,
        pingInterval:
            Duration(seconds: 10)); // buat konekin ke server websocket
    // buat listen data dari server websocket
    channel!.stream.listen(
      (event) {
        Map<String, dynamic> message = jsonDecode(event);
        

        // if (message['event'] == 'message.created') {
        //   messageController.add(message['data']);
        // }
        // Add more if .. else if .. else statements for other events.
      },
      onDone: () {
        debugPrint('Connection closed');
      },
      onError: (error) {
        debugPrint('Error: $error');
      },
    );
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
