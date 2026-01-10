import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// WebSocket event types from server
class WebSocketEvent {
  final String type;
  final Map<String, dynamic> payload;
  
  WebSocketEvent({required this.type, required this.payload});
  
  factory WebSocketEvent.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final payload = Map<String, dynamic>.from(json)..remove('type');
    return WebSocketEvent(type: type, payload: payload);
  }
}

/// WebSocket service for real-time updates
class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  bool _isConnected = false;
  bool _shouldReconnect = true;
  
  // Event stream controller for broadcasting events to listeners
  final _eventController = StreamController<WebSocketEvent>.broadcast();
  Stream<WebSocketEvent> get events => _eventController.stream;
  
  // Base URL for WebSocket (same as API but with ws:// protocol)
  String get _wsUrl {
    // In dev, API is on localhost:8000
    // For production, this should be configured dynamically
    const apiHost = '57.131.20.93/api';
    return 'ws://$apiHost/ws';
  }
  
  /// Connect to WebSocket server
  Future<void> connect() async {
    if (_isConnected) return;
    
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    if (token == null) {
      print('WebSocket: No auth token, skipping connection');
      return;
    }
    
    try {
      final uri = Uri.parse('$_wsUrl?token=$token');
      print('WebSocket: Connecting to $uri');
      
      _channel = WebSocketChannel.connect(uri);
      
      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );
      
      _isConnected = true;
      _shouldReconnect = true;
      
      // Start ping timer to keep connection alive
      _startPingTimer();
      
      print('WebSocket: Connected');
    } catch (e) {
      print('WebSocket: Connection error: $e');
      _scheduleReconnect();
    }
  }
  
  /// Disconnect from WebSocket server
  void disconnect() {
    _shouldReconnect = false;
    _cleanup();
    print('WebSocket: Disconnected');
  }
  
  void _cleanup() {
    _isConnected = false;
    _pingTimer?.cancel();
    _pingTimer = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
  }
  
  void _onMessage(dynamic data) {
    try {
      if (data == 'pong') {
        // Ping response, ignore
        return;
      }
      
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      final event = WebSocketEvent.fromJson(json);
      
      print('WebSocket: Received event: ${event.type}');
      _eventController.add(event);
    } catch (e) {
      print('WebSocket: Error parsing message: $e');
    }
  }
  
  void _onError(dynamic error) {
    print('WebSocket: Error: $error');
    _cleanup();
    _scheduleReconnect();
  }
  
  void _onDone() {
    print('WebSocket: Connection closed');
    _cleanup();
    _scheduleReconnect();
  }
  
  void _scheduleReconnect() {
    if (!_shouldReconnect) return;
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      print('WebSocket: Attempting reconnect...');
      connect();
    });
  }
  
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isConnected && _channel != null) {
        try {
          _channel!.sink.add('ping');
        } catch (e) {
          print('WebSocket: Ping error: $e');
        }
      }
    });
  }
  
  /// Dispose the service
  void dispose() {
    disconnect();
    _eventController.close();
  }
}

/// Singleton instance
final webSocketService = WebSocketService();

/// Provider for WebSocket events stream
final webSocketEventsProvider = StreamProvider<WebSocketEvent>((ref) {
  // Ensure connected when provider is first read
  webSocketService.connect();
  
  ref.onDispose(() {
    // Don't disconnect on dispose since it's a singleton
    // webSocketService.disconnect();
  });
  
  return webSocketService.events;
});

/// Provider to listen for specific event types
final webSocketEventProvider = Provider.family<Stream<WebSocketEvent>, String>((ref, eventType) {
  return webSocketService.events.where((event) => event.type == eventType);
});
