import Foundation
import Twitch

@MainActor
@Observable public final class ChannelEventState {
  public enum State: Equatable {
    case idle, connecting, connected
    case error(String)
  }

  public let channelID: String

  public private(set) var state: State = .idle
  public private(set) var chatMessages: [ChannelChatMessageEvent] = []

  @ObservationIgnored private var tasks: [Task<Void, Never>] = []
  @ObservationIgnored private var sessionID: UUID?

  public init(channelID: String) {
    self.channelID = channelID
  }

  public func start(context: TwitchClientStore.Context) {
    self.stop()

    sessionID = context.id
    state = .connecting

    tasks = [
      Task { await self.consumeChatMessages(context: context, channelID: channelID) }
    ]
  }

  public func stop() {
    tasks.forEach { $0.cancel() }
    tasks.removeAll()
    sessionID = nil
    state = .idle
    chatMessages = []
  }

  private func consumeChatMessages(
    context: TwitchClientStore.Context,
    channelID: String
  ) async {
    do {
      let stream = try await context.client.eventStream(
        for: .chatMessage(broadcasterID: channelID, userID: context.userID)
      )

      await MainActor.run { self.state = .connected }

      for try await event in stream {
        guard sessionID == context.id else { return }
        await MainActor.run { self.chatMessages.append(event) }
      }
    } catch {
      guard sessionID == context.id else { return }
      await MainActor.run { self.state = .error(String(describing: error)) }
    }
  }
}
