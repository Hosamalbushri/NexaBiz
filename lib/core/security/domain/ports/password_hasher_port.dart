/// Domain Port for password hashing and verification.
///
/// Domain contracts MUST NOT know concrete cryptographic details.
abstract class PasswordHasherPort {
  String hashPassword(String password, String salt);
  bool verifyPassword(String password, String storedHash, String salt);
}
