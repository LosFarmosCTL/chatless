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

  @State private var editMode: EditMode = .inactive

  @State private var showingMentions = false

  @State private var searchText = ""
  @State private var isSearching: Bool = false
  internal var isRefreshing: Bool

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
      .toolbarTitleDisplayMode(.inlineLarge)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) { EditButton() }
        ToolbarSpacer(.fixed, placement: .topBarTrailing)

        if !editMode.isEditing {
          AccountToolbarItem(placement: .topBarTrailing, isLoading: isRefreshing)
        }

        DefaultToolbarItem(kind: .search, placement: .bottomBar)
        ToolbarSpacer(.flexible, placement: .bottomBar)
        MentionsToolbarItem(placement: .bottomBar, showingMentions: $showingMentions)
      }
      .environment(\.editMode, $editMode)
      .searchable(
        text: $searchText,
        isPresented: $isSearching,
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
