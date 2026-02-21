#if DEBUG
  import Foundation
  import SwiftData

  @MainActor
  public struct PreviewHelper {
    public static func authSetup(loggedIn: Bool = true, numOfAccounts: Int = 1) -> (
      AuthenticationStore, ModelContainer
    ) {
      let config = ModelConfiguration(isStoredInMemoryOnly: true)

      // swiftlint:disable:next force_try
      let container = try! ModelContainer(for: AuthenticatedUser.self, configurations: config)
      let mockCredentials = PreviewCredentialsService()

      let store = AuthenticationStore(
        modelContext: container.mainContext,
        credentials: mockCredentials
      )

      if loggedIn {
        for _ in 0..<numOfAccounts {
          let dummyUser = AuthenticatedUser(
            id: "preview_\(Int.random(in: 0...100))",
            displayName: "PreviewStreamer\(Int.random(in: 10000...99999))",
            login: "previewstreamer",
            profileImageURL: nil,
            lastLogin: Date()
          )
          let dummyTokens = AuthToken(
            accessToken: "preview_token",
            expirationDate: Date().addingTimeInterval(86400)
          )

          container.mainContext.insert(dummyUser)
          mockCredentials.save(dummyTokens, for: dummyUser.id)
          store.activeUserID = dummyUser.id
        }
      }

      return (store, container)
    }
  }

  final class PreviewCredentialsService: CredentialsService {
    private var storage: [String: AuthToken] = [:]

    func save(_ tokens: AuthToken, for userID: String) {
      storage[userID] = tokens
    }

    func load(for userID: String) -> AuthToken? {
      storage[userID]
    }

    func delete(for userID: String) {
      storage.removeValue(forKey: userID)
    }
  }
#endif
