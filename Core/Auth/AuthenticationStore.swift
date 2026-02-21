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
    self.activeUserID = storedID

    // Check token validity on boot; clear if expired/missing
    if let id = storedID, let tokens = credentials.load(for: id),
      !credentials.isExpired(tokens)
    {
      // Session is valid
    } else {
      self.activeUserID = nil
    }
  }

  public var activeProfile: AuthenticatedUser? {
    guard let id = activeUserID else { return nil }
    let descriptor = FetchDescriptor<AuthenticatedUser>(
      predicate: #Predicate { $0.id == id }
    )
    return try? modelContext.fetch(descriptor).first
  }

  public var activeTokens: AuthToken? {
    guard let id = activeUserID else { return nil }
    return credentials.load(for: id)
  }

  public func login(profile: AuthenticatedUser, token: AuthToken) async {
    let targetID = profile.id
    let descriptor = FetchDescriptor<AuthenticatedUser>(
      predicate: #Predicate { $0.id == targetID }
    )

    if let existing = try? modelContext.fetch(descriptor).first {
      existing.displayName = profile.displayName
      existing.login = profile.login
      existing.profileImageURL = profile.profileImageURL
      existing.lastLogin = Date()
    } else {
      modelContext.insert(profile)
    }

    try? modelContext.save()

    credentials.save(token, for: targetID)
    activeUserID = targetID
  }

  public func switchTo(id: String) {
    if let tokens = credentials.load(for: id), !credentials.isExpired(tokens) {
      activeUserID = id
    } else {
      activeUserID = nil
    }
  }

  public func removeAccount(id: String, deleteProfile: Bool = true) {
    credentials.delete(for: id)

    if deleteProfile {
      let descriptor = FetchDescriptor<AuthenticatedUser>(
        predicate: #Predicate { $0.id == id }
      )
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
    guard let tokens = activeTokens else { return false }
    return !credentials.isExpired(tokens)
  }

  public func hasValidTokens(for id: String) -> Bool {
    if let tokens = credentials.load(for: id), !credentials.isExpired(tokens) {
      return true
    }
    return false
  }
}
