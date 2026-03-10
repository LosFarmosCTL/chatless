import Foundation

public struct AuthToken: Codable {
  public let clientID: String
  public let accessToken: String
  public let expirationDate: Date?

  public init(
    clientID: String = TwitchAuthURL.clientID,
    accessToken: String,
    expirationDate: Date?,
  ) {
    self.clientID = clientID
    self.accessToken = accessToken
    self.expirationDate = expirationDate
  }

  public func isExpired(skew: TimeInterval = 60) -> Bool {
    guard let expirationDate else { return false }

    return expirationDate.timeIntervalSinceNow <= skew
  }
}
