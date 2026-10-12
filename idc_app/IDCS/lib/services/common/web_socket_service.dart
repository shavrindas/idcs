// ===============================================================
// 경로: lib/services/common/web_socket_service.dart
// 명세: 제어판 실시간 값을 받는 웹소켓 연결 (끊기면 스스로 다시 붙는다)
// ===============================================================
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// 서버와의 실시간 연결 하나를 돌본다.
///
/// 현장에서는 끊기는 쪽이 정상이다 — 서버가 재시작되고, 와이파이가 바뀌고,
/// 화면을 오래 켜 두면 중간 장비가 조용히 연결을 닫는다. 그래서 이 클래스는
/// 연결이 **어떻게** 끝났든 다시 붙는 것을 기본으로 삼는다. 예전에는 에러로
/// 끊길 때만 다시 붙었고, 서버가 정상적으로 닫으면(onDone) 그대로 멈춰
/// 제어판이 'NA' 와 '데이터 기다리는 중' 에서 영원히 머물렀다.
class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _retryTimer;

  /// 다시 붙을 주소. disconnect() 전까지 들고 있는다.
  String? _url;

  /// 사용자가 화면을 떠난 것인지. 이 경우에는 다시 붙지 않는다.
  bool _disposed = false;

  /// 연속 실패 횟수. 재시도 간격을 늘리는 데 쓴다.
  int _attempt = 0;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  final StreamController<String> _messageStreamController = StreamController<String>.broadcast();
  Stream<String> get messageStream => _messageStreamController.stream;

  /// 서버가 내려가 있을 때 3초마다 두드리면 로그만 쌓이고 배터리만 먹는다.
  /// 실패가 이어지면 간격을 늘리되, 30초를 넘기지는 않는다 — 현장에서는
  /// 서버가 돌아온 뒤 화면이 살아나기까지의 시간이 그대로 체감된다.
  static const Duration _minRetry = Duration(seconds: 2);
  static const Duration _maxRetry = Duration(seconds: 30);

  Future<void> connect(String url) async {
    _url = url;
    _disposed = false;
    await _open();
  }

  Future<void> _open() async {
    final url = _url;
    if (_disposed || url == null) return;

    _retryTimer?.cancel();

    try {
      final channel = WebSocketChannel.connect(Uri.parse(url));
      _channel = channel;

      // 핸드셰이크가 끝나야 실제로 보낼 수 있다. 예전에는 connect() 직후에
      // 바로 연결됨으로 표시해서, 아직 열리지 않은 소켓에 제어 명령을 넣고도
      // 보낸 것으로 알았다.
      await channel.ready;
      if (_disposed) {
        await channel.sink.close();
        return;
      }

      _isConnected = true;
      _attempt = 0;

      _subscription = channel.stream.listen(
        (message) {
          if (!_messageStreamController.isClosed) {
            _messageStreamController.add(message.toString());
          }
        },
        onError: (error) {
          debugPrint('웹소켓 에러 발생: $error');
          _scheduleRetry();
        },
        onDone: () {
          debugPrint('웹소켓 연결 종료 (코드: ${channel.closeCode})');
          _scheduleRetry();
        },
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('웹소켓 연결 실패: $e');
      _scheduleRetry();
    }
  }

  void _scheduleRetry() {
    _isConnected = false;
    _subscription?.cancel();
    _subscription = null;

    // 화면을 떠났거나 이미 다음 시도가 예약돼 있으면 더 쌓지 않는다.
    // onError 와 onDone 이 잇따라 오는 경우가 있어 이 확인이 필요하다.
    if (_disposed || _retryTimer?.isActive == true) return;

    final seconds = (_minRetry.inSeconds * (1 << _attempt)).clamp(
      _minRetry.inSeconds,
      _maxRetry.inSeconds,
    );
    _attempt = (_attempt + 1).clamp(0, 5);

    _retryTimer = Timer(Duration(seconds: seconds), _open);
  }

  void disconnect() {
    _disposed = true;
    _isConnected = false;
    _retryTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _messageStreamController.close();
  }

  void send(String message) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(message);
    } else {
      debugPrint('웹소켓이 연결되어 있지 않아 메시지를 전송할 수 없습니다.');
    }
  }
}
