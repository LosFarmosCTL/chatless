import Chat
import Shared
import SwiftData
import SwiftUI
import Twitch
import TwitchSession

public struct SearchView: View {
  enum TwitchResults {
    case loading
    case loaded([Channel])
    case error(String)
  }

  private let debounceDuration: Duration = .milliseconds(300)

  @Environment(\.dismissSearch) private var dismissSearch
  @Environment(\.modelContext) private var modelContext

  @Environment(AppRouter.self) private var router
  @Environment(TwitchAPIService.self) private var twitchAPI
  @Environment(ChannelStatusStore.self) private var channelStatusStore

  @State private var results: TwitchResults = .loaded([])

  private let searchText: String
  private var query: String {
    searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
  }

  @Query private var channels: [AddedChannel]

  public init(searchText: String) {
    self.searchText = searchText

    let query = self.query
    self._channels = Query(filter: #Predicate { $0.login.contains(query) })
  }

  public var body: some View {
    Group {
      if query.isEmpty {
        ContentUnavailableView(
          "Search Twitch",
          systemImage: "magnifyingglass",
          description: Text("Try searching for a channel."))
      } else {
        SearchResultsView(
          addedChannels: channels,
          twitchResults: results,
        ) { action in
          switch action {
          case .openChannel(let channelID):
            openChannel(channelID: channelID)
          case .addChannel(let channel):
            addChannel(channel: channel)
          }
        }
      }
    }
    .task(id: query) { await runSearch() }
  }

  @MainActor
  private func runSearch() async {
    guard !query.isEmpty else {
      results = .loading
      return
    }

    do {
      results = .loading

      try await Task.sleep(for: debounceDuration)
      try Task.checkCancellation()

      let channels = try await twitchAPI.request(.searchChannels(for: query, limit: 40)).channels
        .filter { channel in !self.channels.contains(where: { $0.id == channel.id }) }
        .prioritizingExactMatch(query: query)

      results = .loaded(channels)
    } catch is CancellationError {
      results = .loading
    } catch {
      results = .error(error.localizedDescription)
    }
  }

  private func addChannel(channel: Channel) {
    if !channels.contains(where: { $0.id == channel.id }) {
      modelContext.insert(
        AddedChannel(
          id: channel.id,
          login: channel.login,
          displayName: channel.name,
          profileImageURL: channel.profilePictureURL))

      try? modelContext.save()

      channelStatusStore.update(
        channelID: channel.id,
        isLive: channel.isLive,
        title: channel.title)
    }

    openChannel(channelID: channel.id)
  }

  private func openChannel(channelID: String) {
    dismissSearch()
    router.push(.chat(channelID: channelID))
  }
}

extension Array where Element == Channel {
  fileprivate func prioritizingExactMatch(query: String) -> [Element] {
    let lowerQuery = query.lowercased()
    var results = self

    if let index = results.firstIndex(where: { $0.login.lowercased() == lowerQuery }) {
      print("Found exact match at index \(index)")
      let match = results.remove(at: index)
      results.insert(match, at: 0)
    }

    return results
  }
}
