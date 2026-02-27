import SwiftUI
import TwitchSession

public struct ChatView: View {
  @ObservedObject private var state: ChannelEventState

  public init(state: ChannelEventState) {
    self.state = state
  }

  public var body: some View {
    Text("State: \(state.state)")
    List(state.chatMessages, id: \.messageID) { message in
      VStack(alignment: .leading, spacing: 4) {
        Text(message.chatterLogin)
          .font(.caption)
          .foregroundStyle(.secondary)
        Text(message.message.text)
          .font(.body)
      }
    }
    .navigationTitle("Chat")
  }
}
