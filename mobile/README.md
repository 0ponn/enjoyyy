# Witchat Mobile

Flutter mobile app for Witchat - anonymous ephemeral chat with ambient presence.

## Setup

```bash
cd mobile
flutter pub get
```

## Development

```bash
# Run on connected device/emulator
flutter run

# Run with hot reload
flutter run --hot
```

## Production Build

```bash
# Android APK
flutter build apk

# iOS
flutter build ios
```

## Architecture

- **State Management**: flutter_riverpod
- **Socket Connection**: socket_io_client
- **Theming**: Dark theme with witch/occult aesthetics

## Project Structure

```
lib/
├── main.dart           # Entry point
├── app.dart            # MaterialApp setup
├── theme/              # Colors, gradients, theme data
├── models/             # Message, Identity, Attention
├── services/           # Socket.io singleton
├── providers/          # Riverpod state providers
├── screens/            # Main chat screen
└── widgets/            # UI components
```

## Connection

Connects to production socket server:
- URL: `wss://witchat.0pon.com`
- Path: `/api/socketio`

## Features

- Real-time messaging with socket.io
- Rule of Three visibility (newest 3 messages fully visible)
- Mood-based gradient backgrounds (calm/neutral/intense)
- Anonymous or revealed identity
- Slash commands (/help, /clear, /id, /mood, etc.)
- Ambient floating particles
- Glass morphism UI design
