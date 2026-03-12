import Auth
import Foundation
import Twitch

@MainActor
@Observable public final class TwitchClientStore {
  public struct Context {
    public let id: UUID
    public let client: TwitchClient
    public let userID: String
  }

  public private(set) var context: Context?

  public init() {}

  public func activate(account: ActiveAccount) async {
    if let client = context?.client {
      await client.resetEventSub()
    }

    let client = TwitchClient(
      authentication: .init(
        oAuth: account.accessToken,
        clientID: account.clientID,
        userID: account.profile.id,
        userLogin: account.profile.login
      ))

    context = Context(id: UUID(), client: client, userID: account.profile.id)
  }

  public func deactivate() async {
    if let client = context?.client {
      await client.resetEventSub()
    }

    context = nil
  }

}
