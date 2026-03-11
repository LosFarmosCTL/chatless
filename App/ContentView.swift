import Account
import Auth
import Chat
import Mentions
import Search
import SwiftData
import SwiftUI

struct ContentView: View {
  @State private var showingMentions = false

  @State private var searchText = ""
  @State private var isSearching: Bool = false

  var body: some View {
    NavigationStack {
      if isSearching {
        SearchView()
          .toolbar {
            DefaultToolbarItem(kind: .search, placement: .bottomBar)
          }
      } else {
        ChatListView()
          .navigationTitle("Chatless")
          .toolbarTitleDisplayMode(.inline)
          .toolbar {
            AccountToolbarItem(placement: .topBarTrailing)

            FilterChatListToolbarItem(placement: .bottomBar)
            ToolbarSpacer(.fixed, placement: .bottomBar)
            DefaultToolbarItem(kind: .search, placement: .bottomBar)
            ToolbarSpacer(.flexible, placement: .bottomBar)
            MentionsToolbarItem(placement: .bottomBar, showingMentions: $showingMentions)
          }
          .sheet(isPresented: $showingMentions) { MentionsView() }
      }
    }
    .searchable(
      text: $searchText, isPresented: $isSearching,
      prompt: "Search on Twitch")
    //    .searchToolbarBehavior(.minimize)
  }
}

#Preview {
  let (store, container) = PreviewHelper.authSetup(loggedIn: true, numOfAccounts: 4)

  ContentView()
    .environment(store)
    .modelContainer(container)
}
