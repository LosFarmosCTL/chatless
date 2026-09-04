import Account
import Auth
import Chat
import Shared
import SwiftData
import SwiftUI
import TwitchSession

@main
struct ChatlessApp: App {
  private let container: ModelContainer

  @State private var router: AppRouter

  @State private var authenticationStore: AuthenticationStore
  @State private var loginService: LoginService
  @State private var twitchClientStore: TwitchClientStore
  @State private var twitchAPIService: TwitchAPIService

  @State private var channelStore: ChannelStore
  @State private var globalEventState: GlobalEventState

  init() {
    // swiftlint:disable:next force_try
    self.container = try! ModelContainer(for: AuthenticatedUser.self, AddedChannel.self)

    let router = AppRouter()

    let auth = AuthenticationStore(modelContext: container.mainContext)
    let loginService = LoginService(auth: auth)

    let twitchClientStore = TwitchClientStore()
    let twitchAPIService = TwitchAPIService(twitchClientStore: twitchClientStore)
    let channelStore = ChannelStore()
    let globalEventState = GlobalEventState()

    self._router = State(initialValue: router)
    self._authenticationStore = State(initialValue: auth)
    self._loginService = State(initialValue: loginService)
    self._twitchClientStore = State(initialValue: twitchClientStore)
    self._twitchAPIService = State(initialValue: twitchAPIService)
    self._channelStore = State(initialValue: channelStore)
    self._globalEventState = State(initialValue: globalEventState)
  }

  var body: some Scene {
    WindowGroup {
      RootView()
        .modelContainer(container)

        .environment(router)

        .environment(authenticationStore)
        .environment(loginService)

        .environment(twitchClientStore)
        .environment(twitchAPIService)
        .environment(globalEventState)
        .environment(channelStore)
    }
  }
}
