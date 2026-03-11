import Foundation
import Twitch

@MainActor
@Observable public final class GlobalEventState {
  public enum State: Equatable {
    case idle, connecting, connected
    case error(String)
  }

  public private(set) var state: State = .idle
  public private(set) var whispers: [WhisperReceivedEvent] = []
  public private(set) var unreadWhispers: Int = 0

  @ObservationIgnored private var tasks: [Task<Void, Never>] = []
  @ObservationIgnored private var sessionID: UUID?

  public init() {}

  public func start(session: TwitchSessionStore.Session) {
    stop()

    sessionID = session.id
    state = .connecting

    tasks = [
      Task { await self.consumeWhispers(session: session) }
    ]
  }

  public func stop() {
    tasks.forEach { $0.cancel() }
    tasks.removeAll()
    sessionID = nil
    state = .idle
    whispers = []
    unreadWhispers = 0
  }

  public func markWhispersRead() {
    unreadWhispers = 0
  }

  private func consumeWhispers(session: TwitchSessionStore.Session) async {
    do {
      let stream = try await session.client.eventStream(
        for: .whisperReceived(userID: session.userID)
      )

      await MainActor.run { self.state = .connected }

      for try await event in stream {
        guard sessionID == session.id else { return }
        await MainActor.run {
          self.whispers.append(event)
          self.unreadWhispers += 1
        }
      }
    } catch {
      guard sessionID == session.id else { return }
      await MainActor.run { self.state = .error(String(describing: error)) }
    }
  }
}
