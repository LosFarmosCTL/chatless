import Foundation
import SwiftData

@Model
public final class AuthenticatedUser {
  @Attribute(.unique) public var id: String
  public var displayName: String?
  public var login: String
  public var profileImageURL: URL?
  public var lastLogin: Date

  public init(
    id: String,
    displayName: String?,
    login: String,
    profileImageURL: URL?,
    lastLogin: Date
  ) {
    self.id = id
    self.displayName = displayName
    self.login = login
    self.profileImageURL = profileImageURL
    self.lastLogin = lastLogin
  }

  public init(
    id: String,
    displayName: String?,
    login: String,
    profileImageURL: String,
    lastLogin: Date = Date()
  ) {
    self.id = id
    self.displayName = displayName
    self.login = login
    self.profileImageURL = URL(string: profileImageURL)
    self.lastLogin = lastLogin
  }
}
