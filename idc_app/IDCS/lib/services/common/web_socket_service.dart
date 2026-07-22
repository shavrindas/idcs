import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;

  // 💡 화면(UI)에서 이 스트림을 구독(Listen)하여 데이터를 받아갈 통로
  final StreamController<String> _messageStreamController = StreamController<String>.broadcast();
  Stream<String> get messageStream => _messageStreamController.stream;

  /// 웹소켓 서버 연결 시작
  void connect(String url) {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));

      // 서버로부터 데이터 수신 대기 시작
      _channel!.stream.listen(
            (message) {
          // 메시지가 정상 수신되면 스트림 컨트롤러를 통해 구독자들에게 브로드캐스팅
          if (!_messageStreamController.isClosed) {
            _messageStreamController.add(message.toString());
          }
        },
        onError: (error) {
          print('웹소켓 에러 발생: $error');
          _reconnect(url); // 에러 발생 시 재연결 시도
        },
        onDone: () {
          print('웹소켓 연결 종료');
        },
      );
    } catch (e) {
      print('웹소켓 연결 실패: $e');
    }
  }

  /// 연결이 예기치 못하게 끊겼을 때의 자동 재연결 로직
  void _reconnect(String url) {
    Future.delayed(const Duration(seconds: 3), () {
      print('웹소켓 재연결 시도 중...');
      connect(url);
    });
  }

  /// 화면이 완전히 파괴되거나 서비스가 종료될 때 자원 해제
  void disconnect() {
    _channel?.sink.close();
    _messageStreamController.close();
  }


  /// 서버로 메시지(JSON String) 전송
  void send(String message) {
    if (_channel != null) {
      _channel!.sink.add(message);
    } else {
      print('웹소켓이 연결되어 있지 않아 메시지를 전송할 수 없습니다.');
    }
  }
}