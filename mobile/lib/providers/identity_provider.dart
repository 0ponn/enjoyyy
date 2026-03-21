import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/identity.dart';
import '../models/message.dart';
import '../services/socket_service.dart';
import 'socket_provider.dart';

class IdentityNotifier extends StateNotifier<Identity> {
  final SocketService _service;
  StreamSubscription<Map<String, dynamic>>? _identitySub;

  IdentityNotifier(this._service) : super(Identity.empty()) {
    _setupListener();
  }

  void _setupListener() {
    _identitySub = _service.identityStream.listen((data) {
      if (data['type'] == 'connected') {
        state = Identity.fromJson(data);
      } else if (data['type'] == 'revealed') {
        // Update if it's our own reveal confirmation
        final colorStr = data['color'] as String?;
        if (colorStr != null && colorStr == state.colorHex) {
          state = state.copyWith(
            handle: data['handle'] as String?,
            tag: data['tag'] as String?,
            sigil: data['sigil'] != null
                ? Sigil.values.firstWhere(
                    (s) => s.name == data['sigil'],
                    orElse: () => Sigil.spiral,
                  )
                : null,
            isRevealed: true,
          );
        }
      }
    });
  }

  void reveal({String? handle, String? tag, Sigil? sigil}) {
    final payload = <String, dynamic>{};
    if (handle != null) payload['handle'] = handle;
    if (tag != null) payload['tag'] = tag;
    if (sigil != null) payload['sigil'] = sigil.name;

    _service.reveal(payload);

    state = state.copyWith(
      handle: handle ?? state.handle,
      tag: tag ?? state.tag,
      sigil: sigil ?? state.sigil,
      isRevealed: true,
    );
  }

  void goAnonymous() {
    state = state.copyWith(
      handle: null,
      tag: null,
      sigil: null,
      isRevealed: false,
    );
    _service.reveal({});
  }

  @override
  void dispose() {
    _identitySub?.cancel();
    super.dispose();
  }
}

final identityProvider = StateNotifierProvider<IdentityNotifier, Identity>((ref) {
  final socketNotifier = ref.watch(socketProvider.notifier);
  return IdentityNotifier(socketNotifier.service);
});
