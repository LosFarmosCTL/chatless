import Foundation

public protocol CredentialsService {
  func save(_ tokens: AuthToken, for userID: String)
  func load(for userID: String) -> AuthToken?
  func delete(for userID: String)
  func isExpired(_ tokens: AuthToken, skew: TimeInterval) -> Bool
}

extension CredentialsService {
  public func isExpired(_ tokens: AuthToken, skew: TimeInterval = 60) -> Bool {
    if let expirationDate = tokens.expirationDate {
      return expirationDate.timeIntervalSinceNow <= skew
    }

    return false
  }
}

public struct KeychainCredentialsService: CredentialsService {
  public init() {}

  private func key(for userID: String) -> String {
    "twitchTokens_\(userID)"
  }

  public func save(_ tokens: AuthToken, for userID: String) {
    do {
      let data = try JSONEncoder().encode(tokens)
      try Keychain.set(data, forKey: key(for: userID))
    } catch {
      print("Token save failed: \(error)")
    }
  }

  public func load(for userID: String) -> AuthToken? {
    do {
      let data = try Keychain.get(key(for: userID))
      return try JSONDecoder().decode(AuthToken.self, from: data)
    } catch {
      return nil
    }
  }

  public func delete(for userID: String) {
    try? Keychain.delete(key(for: userID))
  }
}
