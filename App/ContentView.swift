import Account
import Auth
import Chat
import Mentions
import Search
import SwiftData
import SwiftUI

struct ContentView: View {
  @Environment(AuthenticationStore.self) private var auth

  @State private var showingMentions = false

  @State private var searchText = ""
  @State private var isSearching: Bool = false

  var body: some View {
    NavigationStack {
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
      .sheet(isPresented: $showingMentions) { MentionsView() }
      .sheet(isPresented: .constant(auth.activeAccount == nil)) {
        AccountManagerView()
          .interactiveDismissDisabled()
          .presentationDetents([.medium, .large])
      }
    }
  }
}
