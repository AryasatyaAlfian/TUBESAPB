enum AppEnvironment { local, staging, production }

class EnvironmentConfig {
  // Default 'local' untuk development, bisa di-override dengan:
  // flutter run --dart-define=APP_ENV=staging
  // flutter run --dart-define=APP_ENV=production
  static const String environmentName =
      String.fromEnvironment('APP_ENV', defaultValue: 'local');

  static AppEnvironment get environment {
    switch (environmentName.toLowerCase()) {
      case 'local':
        return AppEnvironment.local;
      case 'staging':
        return AppEnvironment.staging;
      case 'production':
        return AppEnvironment.production;
      default:
        return AppEnvironment.local;
    }
  }

  static String get baseUrl {
    switch (environment) {
      case AppEnvironment.local:
        return 'http://10.0.2.2:8000/api';
      case AppEnvironment.staging:
        return 'https://staging.example.com/api'; // TODO: Update staging URL
      case AppEnvironment.production:
        return 'https://api.example.com/api'; // TODO: Update production URL
    }
  }

  static bool get isLocal => environment == AppEnvironment.local;
  static bool get isStaging => environment == AppEnvironment.staging;
  static bool get isProduction => environment == AppEnvironment.production;
}
