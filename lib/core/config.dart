class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api-staging.tiyn.dev',
  );

  static const googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );
}
