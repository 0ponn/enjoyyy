import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;
  bool _isConnected = false;
  String? _currentRoom;
  String? _ownColor;

  final _connectionController = StreamController<bool>.broadcast();
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _presenceController = StreamController<int>.broadcast();
  final _moodController = StreamController<String>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  final _identityController = StreamController<Map<String, dynamic>>.broadcast();
  final _attentionController = StreamController<Map<String, dynamic>>.broadcast();
  final _roomTitleController = StreamController<String>.broadcast();
  final _summonedController = StreamController<Map<String, dynamic>>.broadcast();
  final _affirmController = StreamController<Map<String, dynamic>>.broadcast();
  final _copyController = StreamController<Map<String, dynamic>>.broadcast();
  final _ghostsController = StreamController<List<Map<String, dynamic>>>.broadcast();
  final _crosstalkController = StreamController<Map<String, dynamic>>.broadcast();
  final _vanishController = StreamController<String>.broadcast();

  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<int> get presenceStream => _presenceController.stream;
  Stream<String> get moodStream => _moodController.stream;
  Stream<Map<String, dynamic>> get typingStream => _typingController.stream;
  Stream<Map<String, dynamic>> get identityStream => _identityController.stream;
  Stream<Map<String, dynamic>> get attentionStream => _attentionController.stream;
  Stream<String> get roomTitleStream => _roomTitleController.stream;
  Stream<Map<String, dynamic>> get summonedStream => _summonedController.stream;
  Stream<Map<String, dynamic>> get affirmStream => _affirmController.stream;
  Stream<Map<String, dynamic>> get copyStream => _copyController.stream;
  Stream<List<Map<String, dynamic>>> get ghostsStream => _ghostsController.stream;
  Stream<Map<String, dynamic>> get crosstalkStream => _crosstalkController.stream;
  Stream<String> get vanishStream => _vanishController.stream;

  bool get isConnected => _isConnected;
  String? get currentRoom => _currentRoom;
  String? get ownColor => _ownColor;

  void connect({String? preferredColor, String? room}) {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
    }

    _socket = io.io(
      'https://witchat.0pon.com',
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setPath('/api/socketio/')
          .enableForceNew()
          .disableAutoConnect()
          .build(),
    );

    _setupListeners();
    _socket!.connect();

    // Send join after connection
    _socket!.onConnect((_) {
      final joinPayload = <String, dynamic>{};
      if (preferredColor != null) {
        joinPayload['color'] = preferredColor;
      }
      if (room != null) {
        joinPayload['room'] = room;
      }
      _socket!.emit('join', joinPayload);
    });
  }

  void _setupListeners() {
    _socket!.onConnect((_) {
      _isConnected = true;
      _connectionController.add(true);
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      _connectionController.add(false);
    });

    _socket!.onError((error) {
      _isConnected = false;
      _connectionController.add(false);
    });

    _socket!.on('connected', (data) {
      if (data is Map<String, dynamic>) {
        _ownColor = data['color'] as String?;
        _currentRoom = data['room'] as String?;
        _identityController.add({'type': 'connected', ...data});
      }
    });

    _socket!.on('message', (data) {
      if (data is Map<String, dynamic>) {
        _messageController.add(data);
      }
    });

    _socket!.on('presence', (data) {
      if (data is int) {
        _presenceController.add(data);
      } else if (data is Map<String, dynamic>) {
        _presenceController.add(data['count'] as int? ?? 0);
      }
    });

    _socket!.on('mood', (data) {
      if (data is String) {
        _moodController.add(data);
      } else if (data is Map<String, dynamic>) {
        _moodController.add(data['mood'] as String? ?? 'neutral');
      }
    });

    _socket!.on('typing', (data) {
      if (data is Map<String, dynamic>) {
        _typingController.add({'typing': true, ...data});
      }
    });

    _socket!.on('typing-stop', (data) {
      if (data is Map<String, dynamic>) {
        _typingController.add({'typing': false, ...data});
      }
    });

    _socket!.on('identity-revealed', (data) {
      if (data is Map<String, dynamic>) {
        _identityController.add({'type': 'revealed', ...data});
      }
    });

    _socket!.on('attention', (data) {
      if (data is Map<String, dynamic>) {
        _attentionController.add(data);
      }
    });

    _socket!.on('room-title', (data) {
      if (data is String) {
        _roomTitleController.add(data);
      }
    });

    _socket!.on('summoned', (data) {
      if (data is Map<String, dynamic>) {
        _summonedController.add(data);
      }
    });

    _socket!.on('affirm', (data) {
      if (data is Map<String, dynamic>) {
        _affirmController.add(data);
      }
    });

    _socket!.on('copy', (data) {
      if (data is Map<String, dynamic>) {
        _copyController.add(data);
      }
    });

    _socket!.on('presence-ghosts', (data) {
      if (data is List) {
        _ghostsController.add(
          data.map((e) => e as Map<String, dynamic>).toList(),
        );
      }
    });

    _socket!.on('crosstalk', (data) {
      if (data is Map<String, dynamic>) {
        _crosstalkController.add(data);
      }
    });

    _socket!.on('vanish', (data) {
      if (data is Map<String, dynamic>) {
        final messageId = data['messageId'] as String?;
        if (messageId != null) {
          _vanishController.add(messageId);
        }
      }
    });
  }

  void sendMessage(String text) {
    if (_socket != null && _isConnected && text.isNotEmpty) {
      _socket!.emit('message', {'text': text});
    }
  }

  void sendTyping() {
    if (_socket != null && _isConnected) {
      _socket!.emit('typing');
    }
  }

  void sendTypingStop() {
    if (_socket != null && _isConnected) {
      _socket!.emit('typing-stop');
    }
  }

  void reveal(Map<String, dynamic> identity) {
    if (_socket != null && _isConnected) {
      _socket!.emit('reveal', identity);
    }
  }

  void focus() {
    if (_socket != null && _isConnected) {
      _socket!.emit('focus');
    }
  }

  void blur() {
    if (_socket != null && _isConnected) {
      _socket!.emit('blur');
    }
  }

  void away() {
    if (_socket != null && _isConnected) {
      _socket!.emit('away');
    }
  }

  void back() {
    if (_socket != null && _isConnected) {
      _socket!.emit('back');
    }
  }

  void notifyCopy(String messageId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('copy', {'messageId': messageId});
    }
  }

  void affirm(String messageId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('affirm', {'messageId': messageId});
    }
  }

  void joinRoom(String room) {
    if (_socket != null && _isConnected) {
      _currentRoom = room;
      _socket!.emit('join', {'room': room});
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _isConnected = false;
    _connectionController.add(false);
  }

  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _connectionController.close();
    _messageController.close();
    _presenceController.close();
    _moodController.close();
    _typingController.close();
    _identityController.close();
    _attentionController.close();
    _roomTitleController.close();
    _summonedController.close();
    _affirmController.close();
    _copyController.close();
    _ghostsController.close();
    _crosstalkController.close();
    _vanishController.close();
  }
}
