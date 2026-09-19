class AppConstants {
  static const String appName = 'FieldAI';
  static const String appTagline = 'Intelligence for the field. Even without internet.';
  static const String apiBaseUrl = 'http://10.0.2.2:8000/api/v1'; // Android Emulator default (or localhost for iOS)
  
  // Storage keys
  static const String keyAuthToken = 'fieldai_auth_token';
  static const String keyUserData = 'fieldai_user_data';
  static const String keyOfflineMode = 'fieldai_offline_mode';

  // Disease classes
  static const List<String> supportedClasses = [
    'Healthy Tomato',
    'Early Blight (Alternaria solani)',
    'Late Blight (Phytophthora infestans)',
    'Leaf Mold (Passalora fulva)',
    'Septoria Leaf Spot',
  ];
}
