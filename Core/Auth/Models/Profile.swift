import Foundation

public struct Profile: Equatable {
  public let id: String
  public let displayName: String
  public let login: String
  public let profileImageURL: URL?

  public init(
    id: String,
    displayName: String,
    login: String,
    profileImageURL: URL?
  ) {
    self.id = id
    self.displayName = displayName
    self.login = login
    self.profileImageURL = profileImageURL
  }

  init(_ user: AuthenticatedUser) {
    self.init(
      id: user.id,
      displayName: user.displayName,
      login: user.login,
      profileImageURL: user.profileImageURL
    )
  }
}
