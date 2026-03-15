import Chat
import MemberwiseInit
import SwiftUI
import Twitch

enum SearchResultAction {
  case addChannel(channel: Channel)
  case openChannel(id: String)
}

struct SearchResultsView: View {
  private let maxTwitchResults = 5
  private let skeletonWidths: [CGFloat] = [96, 142, 118, 168, 104]

  let addedChannels: [AddedChannel]
  let twitchResults: SearchView.TwitchResults
  let onResultAction: (SearchResultAction) -> Void

  var body: some View {
    List {
      if !addedChannels.isEmpty {
        Section(header: Text("Added Channels")) {
          ForEach(addedChannels, id: \.id) { channel in
            Button {
              onResultAction(.openChannel(id: channel.id))
            } label: {
              Text(channel.displayName)
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
                onResultAction(.addChannel(channel: channel))
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
    addedChannels: [
      .init(
        id: "1",
        login: "forsen",
        displayName: "forsen",
        profileImageURL:
          "https://static-cdn.jtvnw.net/jtv_user_pictures/forsen-profile_image-48b43e1e4f54b5c8-300x300.png",
      ),
      .init(
        id: "2",
        login: "forsen",
        displayName: "forsen",
        profileImageURL:
          "https://static-cdn.jtvnw.net/jtv_user_pictures/forsen-profile_image-48b43e1e4f54b5c8-300x300.png",
      ),
    ],
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
    addedChannels: [
      .init(
        id: "1",
        login: "forsen",
        displayName: "forsen",
        profileImageURL:
          "https://static-cdn.jtvnw.net/jtv_user_pictures/forsen-profile_image-48b43e1e4f54b5c8-300x300.png",
      ),
      .init(
        id: "2",
        login: "forsen",
        displayName: "forsen",
        profileImageURL:
          "https://static-cdn.jtvnw.net/jtv_user_pictures/forsen-profile_image-48b43e1e4f54b5c8-300x300.png",
      ),
    ],
    twitchResults: .loading,
    onResultAction: { _ in }
  )
}
