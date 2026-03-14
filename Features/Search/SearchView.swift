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

  @Environment(\.dismissSearch) private var dismissSearch
  @Environment(\.modelContext) private var modelContext

  @Environment(AppRouter.self) private var router
  @Environment(TwitchAPIService.self) private var twitchAPI

  @State private var results: TwitchResults = .loaded([])

  private let debounceDuration: Duration = .milliseconds(300)
  private let searchText: String

  @Query private var channels: [ChatChannel]

  public init(searchText: String) {
    self.searchText = searchText

    self._channels = Query(filter: #Predicate { $0.channelID.contains(searchText) })
  }

  public var body: some View {
    Group {
      if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        ContentUnavailableView(
          "Search Twitch",
          systemImage: "magnifyingglass",
          description: Text("Try searching for a channel."))
      } else {
        SearchResultsView(
          favoriteChannels: channels,
          twitchResults: results,
        ) { action in
          switch action {
          case .openFavorite(let channelID):
            openChannel(channelID: channelID)
          case .addFavorite(let channelID):
            addFavorite(channelID: channelID)
          }
        }
      }
    }
    .task(id: searchText) {
      await runSearch()
    }
  }

  @MainActor
  private func runSearch() async {
    let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !query.isEmpty else {
      results = .loading
      return
    }

    do {
      results = .loading

      try await Task.sleep(for: debounceDuration)
      try Task.checkCancellation()

      let (channels, _) = try await twitchAPI.request(.searchChannels(for: query, limit: 40))

      results = .loaded(channels.prioritizingExactMatch(query: query))
    } catch is CancellationError {
      results = .loading
    } catch {
      results = .error(error.localizedDescription)
    }
  }

  private func addFavorite(channelID: String) {
    let trimmed = channelID.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }

    if !channels.contains(where: { $0.channelID == trimmed }) {
      modelContext.insert(ChatChannel(channelID: trimmed))
      try? modelContext.save()
    }

    openChannel(channelID: trimmed)
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
