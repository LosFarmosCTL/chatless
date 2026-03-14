import Account
import Auth
import Chat
import Mentions
import Search
import Shared
import SwiftData
import SwiftUI
import TwitchSession

struct ContentView: View {
  @Environment(AppRouter.self) private var router

  @Environment(AuthenticationStore.self) private var auth
  @Environment(ChannelEventStateRegistry.self) private var channelRegistry

  @State private var showingMentions = false

  @State private var searchText = ""
  @State private var isSearching: Bool = false

  var body: some View {
    @Bindable var router = router

    NavigationStack(path: $router.path) {
      ZStack {
        if isSearching {
          SearchView(searchText: searchText)
        } else {
          ChatListView()
        }
      }
      .navigationTitle("Chatless")
      .toolbarTitleDisplayMode(.inline)
      .toolbar {
        MentionsToolbarItem(placement: .topBarTrailing, showingMentions: $showingMentions)
        AccountToolbarItem(placement: .topBarTrailing)

        FilterChatListToolbarItem(placement: .bottomBar)
        ToolbarSpacer(.flexible, placement: .bottomBar)
        DefaultToolbarItem(kind: .search, placement: .bottomBar)
      }
      .searchable(
        text: $searchText,
        isPresented: $isSearching,
        prompt: "Search on Twitch"
      )
      .navigationDestination(for: AppRoute.self) { route in
        switch route {
        case .chat(let channelID):
          ChatView(state: channelRegistry.getOrCreateChannel(channelID))
        }
      }
      .sheet(isPresented: $showingMentions) { MentionsView() }
      .sheet(isPresented: .constant(auth.activeAccount == nil)) {
        AccountManagerView()
          .interactiveDismissDisabled()
          .presentationDetents([.medium, .large])
      }
    }
  }
}
