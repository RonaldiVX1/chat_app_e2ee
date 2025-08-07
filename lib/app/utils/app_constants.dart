class AppConstants {
  // API
  static const String baseUrl = 'http://10.247.215.236:8081';
  
  // Storage Keys
  static const String tokenKey = 'token';
  static const String userKey = 'user';
  static const String privateKeyKey = 'private_key';
  
  // Routes
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String homeRoute = '/home';
  static const String chatRoute = '/chat';
  
  // Messages
  static const String loginSuccess = 'Login successful';
  static const String loginFailed = 'Login failed. Check your credentials.';
  static const String registerSuccess = 'Registration successful';
  static const String registerFailed = 'Registration failed';
  static const String logoutSuccess = 'Logged out successfully';
  static const String messageSendFailed = 'Failed to send message';
  static const String noMessages = 'No messages yet. Start the conversation!';
  static const String noUsers = 'No users available';
  
  // Validation Messages
  static const String usernameEmpty = 'Username cannot be empty';
  static const String passwordEmpty = 'Password cannot be empty';
  static const String passwordTooShort = 'Password must be at least 6 characters';
  
  // Error Messages
  static const String privateKeyNotFound = 'Error: Private key not found';
  static const String publicKeyImportError = 'Error: Could not import receiver\'s public key';
  static const String sharedSecretError = 'Error: Could not derive shared secret';
  static const String encryptionError = 'Error: Could not encrypt message';
  static const String decryptionError = 'Error: Could not decrypt message';
  static const String unauthorizedError = 'Unauthorized: Please login again';
}