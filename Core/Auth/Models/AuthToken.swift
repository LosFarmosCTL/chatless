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
}
