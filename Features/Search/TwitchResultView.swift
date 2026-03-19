import SwiftUI
import Twitch

struct TwitchResultView: View {
  let channel: Channel

  var body: some View {
    HStack(spacing: 8) {
      AsyncImage(url: URL(string: channel.profileImageURL)) { image in
        image.resizable().scaledToFill()
      } placeholder: {
        Circle().fill(.gray.opacity(0.2))
      }
      .frame(width: 32, height: 32)
      .clipShape(Circle())

      VStack(alignment: .leading, spacing: 4) {
        Text(channel.name)
          .font(.headline)

        if channel.isLive && !channel.title.isEmpty {
          Text(channel.title)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
      }

      Spacer()

      if channel.isLive {
        Text("LIVE")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.red)
      }
    }
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
