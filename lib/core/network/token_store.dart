/// Abstraction for access/refresh token persistence (secure storage).
abstract class TokenStore {
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresInSeconds,
  });

  Future<String?> readAccessToken();

  Future<String?> readRefreshToken();

  Future<DateTime?> readAccessExpiresAt();

  Future<void> clear();
}
