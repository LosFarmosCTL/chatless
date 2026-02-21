import Auth
import SwiftData
import SwiftUI

@main
struct ChatlessApp: App {
  private let container: ModelContainer
  @StateObject private var auth: AuthenticationStore

  init() {
    // swiftlint:disable:next force_try
    let localContainer = try! ModelContainer(for: AuthenticatedUser.self)

    let localAuth = AuthenticationStore(
      modelContext: localContainer.mainContext
    )

    self.container = localContainer
    self._auth = StateObject(wrappedValue: localAuth)
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(auth)
        .modelContainer(container)
    }
  }
}
