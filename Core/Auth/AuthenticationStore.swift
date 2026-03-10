import Foundation
import SwiftData
import SwiftUI

@MainActor
public final class AuthenticationStore: ObservableObject {
  @Published public var activeUserID: String? {
    didSet {
      let defaults = UserDefaults.standard
      if let id = activeUserID {
        defaults.set(id, forKey: Self.lastActiveKey)
      } else {
        defaults.removeObject(forKey: Self.lastActiveKey)
      }
    }
  }

  private let modelContext: ModelContext
  private let credentials: any CredentialsService
  private static let lastActiveKey = "lastActiveUserID"

  public init(
    modelContext: ModelContext,
    credentials: any CredentialsService = KeychainCredentialsService()
  ) {
    self.modelContext = modelContext
    self.credentials = credentials

    let storedID = UserDefaults.standard.string(forKey: Self.lastActiveKey)
    if let storedID, !credentials.isExpired(for: storedID) {
      self.activeUserID = storedID
    } else {
      self.activeUserID = nil
    }
  }

  public var activeProfile: AuthenticatedUser? {
    guard let id = activeUserID else { return nil }

    let descriptor = FetchDescriptor<AuthenticatedUser>(predicate: #Predicate { $0.id == id })
    return try? modelContext.fetch(descriptor).first
  }

  public var activeToken: AuthToken? {
    guard let id = activeUserID else { return nil }

    return credentials.load(for: id)
  }

  public func login(profile: AuthenticatedUser, token: AuthToken) async {
    let id = profile.id
    let descriptor = FetchDescriptor<AuthenticatedUser>(predicate: #Predicate { $0.id == id })

    if let existing = try? modelContext.fetch(descriptor).first {
      existing.displayName = profile.displayName
      existing.login = profile.login
      existing.profileImageURL = profile.profileImageURL
      existing.lastLogin = Date()
    } else {
      modelContext.insert(profile)
    }

    try? modelContext.save()

    credentials.save(token, for: profile.id)
    activeUserID = profile.id
  }

  public func switchTo(id: String) {
    activeUserID = if !credentials.isExpired(for: id) { id } else { nil }
  }

  public func removeAccount(id: String, deleteProfile: Bool = true) {
    credentials.delete(for: id)

    if deleteProfile {
      let descriptor = FetchDescriptor<AuthenticatedUser>(predicate: #Predicate { $0.id == id })

      if let profile = try? modelContext.fetch(descriptor).first {
        modelContext.delete(profile)
        try? modelContext.save()
      }
    }

    if activeUserID == id {
      activeUserID = nil
    }
  }

  public func logoutActive(deleteProfile: Bool = false) {
    guard let id = activeUserID else { return }
    removeAccount(id: id, deleteProfile: deleteProfile)
  }

  public func tokenValidForActiveUser() -> Bool {
    return activeToken?.isExpired() == false
  }

  public func hasValidTokens(for id: String) -> Bool {
    return !credentials.isExpired(for: id)
  }
}
