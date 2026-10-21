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
    ChatFeedView(feed: state.feed)
      .safeAreaInset(edge: .top, spacing: 0) {
        if state.connectionStatus != .connected {
          HStack {
            Text("State: \(state.connectionStatus)")
              .font(.caption)
              .foregroundStyle(.secondary)

            if case .failed = state.connectionStatus {
              Button("Retry Chat") {
                channelStore.retryMessages(in: state.channelID)
              }
            }
          }
          .padding(8)
          .frame(maxWidth: .infinity)
          .background(.bar)
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
