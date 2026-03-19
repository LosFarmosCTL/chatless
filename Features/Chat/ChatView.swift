import Shared
import SwiftUI
import TwitchSession

public struct ChatView: View {
  private let events: ChannelEventState

  public init(state: ChannelEventState) {
    self.events = state
  }

  public var body: some View {
    Text("State: \(events.state)")
    List(events.chatMessages, id: \.messageID) { message in
      VStack(alignment: .leading, spacing: 4) {
        Text(message.chatterLogin)
          .font(.caption)
          .foregroundStyle(.secondary)
        Text(message.message.text)
          .font(.body)
      }
    }
    .navigationTitle("Chat")
    .toolbarTitleDisplayMode(.inline)
  }
}

extension ChannelEventState.State: @retroactive CustomLocalizedStringResourceConvertible {
  public var localizedStringResource: LocalizedStringResource {
    switch self {
    case .idle: return .init("Idle")
    case .connecting: return .init("Connecting")
    case .connected: return .init("Connected")
    case .error(let message): return .init("Error: \(message)")
    }
  }
}
