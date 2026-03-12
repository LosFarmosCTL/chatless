public struct ActiveAccount: Equatable {
  public let profile: Profile
  public let accessToken: String
  public let clientID: String

  public init(profile: Profile, accessToken: String, clientID: String) {
    self.profile = profile
    self.accessToken = accessToken
    self.clientID = clientID
  }
}
