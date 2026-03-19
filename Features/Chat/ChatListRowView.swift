import SwiftUI

public struct ChatListRowView: View {
  public let displayName: String
  public let profileImageURL: String

  public let isLive: Bool
  public let title: String?

  public init(
    displayName: String,
    profileImageURL: String,
    isLive: Bool,
    title: String?
  ) {
    self.displayName = displayName
    self.profileImageURL = profileImageURL
    self.isLive = isLive
    self.title = title
  }

  public var body: some View {
    HStack(spacing: 8) {
      AsyncImage(url: URL(string: profileImageURL)) { image in
        image.resizable().scaledToFill()
      } placeholder: {
        Circle().fill(.gray.opacity(0.2))
      }
      .frame(width: 32, height: 32)
      .clipShape(Circle())

      VStack(alignment: .leading, spacing: 4) {
        Text(displayName)
          .font(.headline)

        if isLive, let title, !title.isEmpty {
          Text(title)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
      }

      Spacer()

      if isLive {
        Text("LIVE")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.red)
      }
    }
  }
}
