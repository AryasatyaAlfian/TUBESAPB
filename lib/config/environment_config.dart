enum AppEnvironment { local, staging, production }

class EnvironmentConfig {
  static const String environmentName =
      String.fromEnvironment('APP_ENV', defaultValue: 'production');

  static AppEnvironment get environment {
    switch (environmentName.toLowerCase()) {
      case 'local':
        return AppEnvironment.local;
      case 'staging':
        return AppEnvironment.staging;
      default:
        return AppEnvironment.production;
    }
  }

  static String get baseUrl {
    switch (environment) {
      case AppEnvironment.local:
        return 'http://10.0.2.2:8000/api';
      case AppEnvironment.staging:
        return 'https://staging.example.com/api';
      case AppEnvironment.production:
        return 'https://api.example.com/api';
    }
  }

  static bool get isLocal => environment == AppEnvironment.local;
  static bool get isStaging => environment == AppEnvironment.staging;
  static bool get isProduction => environment == AppEnvironment.production;
}
