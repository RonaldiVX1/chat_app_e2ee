# E2EE Chat App

## Overview

This is a secure end-to-end encrypted (E2EE) chat application built with Flutter and GetX. The app implements ECDH (Elliptic Curve Diffie-Hellman) key exchange for secure communication between users, ensuring that messages can only be read by the intended recipients.

## Features

- **End-to-End Encryption**: All messages are encrypted using AES-GCM with keys derived from ECDH key exchange
- **User Authentication**: Secure login and registration system
- **Real-time Messaging**: Send and receive messages in real-time
- **Message History**: View your conversation history with other users
- **Dark Mode Support**: Automatically adapts to system theme settings
- **Secure Key Storage**: Private keys are securely stored using Flutter Secure Storage

## Architecture

The application follows the GetX pattern with a clean architecture approach:

- **Controllers**: Handle business logic and state management
- **Views**: UI components that react to state changes
- **Providers**: Handle API communication and data persistence
- **Repositories**: Act as intermediaries between controllers and providers
- **Models**: Define data structures
- **Utils**: Contain helper functions and utilities

## Security Implementation

### Key Generation and Exchange

1. During registration, the app generates an ECDH key pair for the user
2. The private key is securely stored on the device using Flutter Secure Storage
3. The public key is sent to the server and associated with the user's account

### Message Encryption Process

1. When sending a message, the sender retrieves the recipient's public key
2. The sender uses their private key and the recipient's public key to derive a shared secret using ECDH
3. The message is encrypted using AES-GCM with the derived shared secret
4. The encrypted message is sent to the server and delivered to the recipient

### Message Decryption Process

1. When receiving a message, the recipient retrieves the sender's public key
2. The recipient uses their private key and the sender's public key to derive the same shared secret
3. The message is decrypted using AES-GCM with the derived shared secret

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK (latest stable version)
- An IDE (VS Code, Android Studio, etc.)

### Installation

1. Clone the repository
2. Navigate to the project directory
3. Run `flutter pub get` to install dependencies
4. No code generation is needed as JSON serialization is implemented manually
5. Connect a device or start an emulator
6. Run `flutter run` to start the application

## Dependencies

- **get**: State management and dependency injection
- **flutter_secure_storage**: Secure storage for sensitive data
- **webcrypto**: Cryptographic operations
- **http**: API communication
- Manual JSON serialization implementation
- **flutter_spinkit**: Loading indicators
- **fluttertoast**: Toast messages

## Best Practices

- Never store private keys or sensitive information in plain text
- Always validate user input
- Implement proper error handling
- Use secure connections (HTTPS) for API communication
- Regularly update dependencies to address security vulnerabilities

## License

This project is licensed under the MIT License - see the LICENSE file for details.
