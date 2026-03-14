import Chat
import MemberwiseInit
import SwiftUI
import Twitch

enum SearchResultAction {
  case addFavorite(channelID: String)
  case openFavorite(channelID: String)
}

struct SearchResultsView: View {
  private let maxTwitchResults = 5
  private let skeletonWidths: [CGFloat] = [96, 142, 118, 168, 104]

  let favoriteChannels: [ChatChannel]
  let twitchResults: SearchView.TwitchResults
  let onResultAction: (SearchResultAction) -> Void

  var body: some View {
    List {
      if !favoriteChannels.isEmpty {
        Section(header: Text("Favorites")) {
          ForEach(favoriteChannels, id: \.id) { channel in
            Button {
              onResultAction(.openFavorite(channelID: channel.channelID))
            } label: {
              Text(channel.channelID)
            }
          }
        }
      }

      Section {
        switch twitchResults {
        case .loading:
          ForEach(0..<maxTwitchResults, id: \.self) { index in
            TwitchResultView.Skeleton(nameBarWidth: skeletonWidths[index])
          }
        case .loaded(let twitchResults):
          if twitchResults.isEmpty {
            ContentUnavailableView(
              "No Results",
              systemImage: "exclamationmark.magnifyingglass",
              description: Text("Couldn't find any channels.")
            )
            .listRowSeparator(.hidden)
          } else {
            ForEach(twitchResults.prefix(maxTwitchResults), id: \.id) { channel in
              Button {
                onResultAction(.addFavorite(channelID: channel.id))
              } label: {
                TwitchResultView(channel: channel)
              }
            }
          }
        case .error(let message):
          ContentUnavailableView(
            "Search Failed",
            systemImage: "exclamationmark.magnifyingglass",
            description: Text(message)
          )
          .listRowSeparator(.hidden)
        }
      } header: {
        HStack(spacing: 6) {
          Text("Twitch")

          if case .loading = twitchResults {
            ProgressView()
              .controlSize(.small)
          }
        }
      }
    }
    .listStyle(.plain)
  }
}

#Preview {
  SearchResultsView(
    favoriteChannels: [.init(channelID: "1"), .init(channelID: "2")],
    twitchResults: .loaded(
      Array(
        repeating: .init(
          id: "22484632",
          login: "forsen",
          name: "forsen",
          language: "en",
          gameID: "509663",
          gameName: "Special Events",
          isLive: false,
          tags: ["English"],
          profilePictureURL:
            "https://static-cdn.jtvnw.net/jtv_user_pictures/forsen-profile_image-48b43e1e4f54b5c8-300x300.png",
          title: "Future Game Show!", startedAt: Date()),
        count: 5)
    ),
    onResultAction: { _ in }
  )
}

#Preview("Loading") {
  SearchResultsView(
    favoriteChannels: [.init(channelID: "1"), .init(channelID: "2")],
    twitchResults: .loading,
    onResultAction: { _ in }
  )
}
