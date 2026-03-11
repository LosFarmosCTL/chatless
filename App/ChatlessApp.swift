import Account
import Auth
import Chat
import SwiftData
import SwiftUI
import TwitchSession

@main
struct ChatlessApp: App {
  private let container: ModelContainer

  @State private var auth: AuthenticationStore
  @State private var loginService: LoginService
  @State private var sessionStore: TwitchSessionStore = TwitchSessionStore()
  @State private var channelEventRegistry: ChannelEventStateRegistry = ChannelEventStateRegistry()
  @State private var globalEventState: GlobalEventState = GlobalEventState()

  init() {
    // swiftlint:disable:next force_try
    self.container = try! ModelContainer(for: AuthenticatedUser.self, ChatChannel.self)
    let auth = AuthenticationStore(modelContext: container.mainContext)

    self._auth = State(initialValue: auth)
    self._loginService = State(initialValue: LoginService(auth: auth))
  }

  var body: some Scene {
    WindowGroup {
      RootView()
        .environment(auth)
        .environment(sessionStore)
        .environment(globalEventState)
        .environment(\.loginService, loginService)
        .environment(\.channelEventRegistry, channelEventRegistry)
        .modelContainer(container)
    }
  }
}
