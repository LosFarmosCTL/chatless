import Foundation
import Twitch

@MainActor
public final class TwitchSessionStore: ObservableObject {
  public struct Session {
    public let id: UUID
    public let client: TwitchClient
    public let userID: String
  }

  public enum State: Equatable {
    case idle
    case connecting
    case connected
    case error(String)
  }

  @Published public private(set) var session: Session?
  @Published public private(set) var state: State = .idle

  public init() {}

  public func switchAccount(to credentials: TwitchCredentials) async {
    state = .connecting

    if let session {
      await session.client.switchCredentials(to: credentials)
      self.session = Session(
        id: UUID(),
        client: session.client,
        userID: credentials.userID)
    } else {
      let client = TwitchClient(authentication: credentials)
      session = Session(id: UUID(), client: client, userID: credentials.userID)
    }

    state = .connected
  }

  public func logout() async {
    if let session {
      await session.client.resetEventSub()
    }

    session = nil
    state = .idle
  }
}
