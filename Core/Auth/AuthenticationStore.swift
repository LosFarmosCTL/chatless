import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable public final class AuthenticationStore {
  private static let lastActiveKey = "lastActiveUserID"

  public enum State: Equatable {
    case none, active
    case expired(Profile)
  }

  @ObservationIgnored private let modelContext: ModelContext
  @ObservationIgnored private let credentials: any CredentialsService

  public private(set) var state: State = .none
  public private(set) var activeAccount: ActiveAccount? {
    didSet {
      let defaults = UserDefaults.standard
      if let userID = self.activeAccount?.profile.id {
        defaults.set(userID, forKey: Self.lastActiveKey)
      } else {
        defaults.removeObject(forKey: Self.lastActiveKey)
      }
    }
  }

  public init(
    modelContext: ModelContext,
    credentials: any CredentialsService = KeychainCredentialsService()
  ) {
    self.modelContext = modelContext
    self.credentials = credentials

    let storedID = UserDefaults.standard.string(forKey: Self.lastActiveKey)
    if let storedID { self.switchTo(accountID: storedID) }
  }

  public func activateAccount(profile: AuthenticatedUser, with token: AuthToken) async {
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

    self.switchTo(accountID: profile.id)
  }

  @discardableResult public func switchTo(accountID: String) -> Bool {
    guard let profile = loadProfile(id: accountID) else {
      activeAccount = nil
      state = .none
      return false
    }

    guard let token = credentials.load(for: accountID), !token.isExpired() else {
      activeAccount = nil
      state = .expired(profile)
      return false
    }

    activeAccount = ActiveAccount(
      profile: profile,
      accessToken: token.accessToken,
      clientID: token.clientID
    )

    state = .active
    return true
  }

  public func removeAccount(id: String, deleteProfile: Bool = true) {
    if activeAccount?.profile.id == id {
      activeAccount = nil
      state = .none
    }

    credentials.delete(for: id)

    if deleteProfile {
      let descriptor = FetchDescriptor<AuthenticatedUser>(predicate: #Predicate { $0.id == id })

      if let profile = try? modelContext.fetch(descriptor).first {
        modelContext.delete(profile)
        try? modelContext.save()
      }
    }
  }

  public func removeActiveAccount() {
    guard let id = activeAccount?.profile.id else { return }
    removeAccount(id: id)
  }

  public func hasValidTokens(for accountID: String) -> Bool {
    return !credentials.isExpired(for: accountID)
  }

  private func loadProfile(id: String) -> Profile? {
    let descriptor = FetchDescriptor<AuthenticatedUser>(predicate: #Predicate { $0.id == id })
    guard let user = try? modelContext.fetch(descriptor).first else { return nil }
    return Profile(user)
  }
}
