import Shared
import SwiftUI
import TwitchSession

public struct ChatView: View {
  @Environment(ChannelStore.self) private var channelStore

  private let state: ChannelState

  public init(state: ChannelState) {
    self.state = state
  }

  public var body: some View {
    Text("State: \(state.connectionStatus)")

    if case .failed = state.connectionStatus {
      Button("Retry Chat") {
        channelStore.retryMessages(in: state.channelID)
      }
    }

    List(state.chatMessages) { message in
      VStack(alignment: .leading, spacing: 4) {
        Text(message.authorLogin)
          .font(.caption)
          .foregroundStyle(.secondary)

        Text(message.rawText)
          .font(.body)
      }
    }
    .navigationTitle("Chat")
    .toolbarTitleDisplayMode(.inline)
  }
}

extension ChatConnectionStatus: CustomLocalizedStringResourceConvertible {
  public var localizedStringResource: LocalizedStringResource {
    switch self {
    case .idle:
      return .init("Idle")
    case .connecting:
      return .init("Connecting")
    case .connected:
      return .init("Connected")
    case .reconnecting(let message):
      return .init("Reconnecting: \(message)")
    case .failed(let message):
      return .init("Error: \(message)")
    }
  }
}
