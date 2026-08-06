import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;

  // 1. 단순 연결 상태 확인용 getter
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  final StreamController<String> _messageStreamController = StreamController<String>.broadcast();
  Stream<String> get messageStream => _messageStreamController.stream;

  void connect(String url) {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));

      // 연결 성공 시점에 true
      _isConnected = true;

      _channel!.stream.listen(
            (message) {
          if (!_messageStreamController.isClosed) {
            _messageStreamController.add(message.toString());
          }
        },
        onError: (error) {
          print('웹소켓 에러 발생: $error');
          _isConnected = false; // 에러 발생 시 false
          _reconnect(url);
        },
        onDone: () {
          print('웹소켓 연결 종료');
          _isConnected = false; // 연결 종료 시 false
        },
      );
    } catch (e) {
      print('웹소켓 연결 실패: $e');
      _isConnected = false; // 예외 발생 시 false
    }
  }

  void _reconnect(String url) {
    _isConnected = false;
    Future.delayed(const Duration(seconds: 3), () {
      print('웹소켓 재연결 시도 중...');
      connect(url);
    });
  }

  void disconnect() {
    _isConnected = false;
    _channel?.sink.close();
    _messageStreamController.close();
  }

  void send(String message) {
    // 2. 조건식 활용 예시
    if (isConnected && _channel != null) {
      _channel!.sink.add(message);
    } else {
      print('웹소켓이 연결되어 있지 않아 메시지를 전송할 수 없습니다.');
    }
  }
}