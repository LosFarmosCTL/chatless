import Chat
import SwiftUI
import Twitch

struct TwitchResultView: View {
  let channel: Channel

  var body: some View {
    ChatListRowView(
      displayName: channel.name,
      profileImageURL: channel.profileImageURL,
      isLive: channel.isLive,
      title: channel.title
    )
  }

  struct Skeleton: View {
    private let nameBarWidth: CGFloat

    init(nameBarWidth: CGFloat = 120) {
      self.nameBarWidth = nameBarWidth
    }

    var body: some View {
      HStack(spacing: 8) {
        Circle()
          .fill(.gray.opacity(0.2))
          .frame(width: 32, height: 32)

        RoundedRectangle(cornerRadius: 4)
          .fill(.gray.opacity(0.2))
          .frame(width: nameBarWidth, height: 18)

        Spacer()
      }
      .redacted(reason: .placeholder)
    }
  }
}

#Preview {
  List {
    TwitchResultView(
      channel: .init(
        id: "22484632",
        login: "forsen",
        name: "forsen",
        language: "en",
        gameID: "509663",
        gameName: "Special Events",
        isLive: false,
        tags: ["English"],
        profileImageURL:
          "https://static-cdn.jtvnw.net/jtv_user_pictures/forsen-profile_image-48b43e1e4f54b5c8-300x300.png",
        title: "Future Game Show!", startedAt: Date()))
  }
  .listStyle(.plain)
}

#Preview("Live") {
  List {
    TwitchResultView(
      channel: .init(
        id: "22484632",
        login: "forsen",
        name: "forsen",
        language: "en",
        gameID: "509663",
        gameName: "Special Events",
        isLive: true,
        tags: ["English"],
        profileImageURL:
          "https://static-cdn.jtvnw.net/jtv_user_pictures/forsen-profile_image-48b43e1e4f54b5c8-300x300.png",
        title: "Future Game Show!", startedAt: Date()))
  }
  .listStyle(.plain)
}
