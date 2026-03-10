import SwiftUI

public struct MentionsView: View {
  public init() {}

  public var body: some View {
    ContentUnavailableView(
      "No mentions/whispers",
      systemImage: "bell.badge.slash",
      description:
        Text("When you are @mentioned in chat, you will see a notification here."))
  }
}
