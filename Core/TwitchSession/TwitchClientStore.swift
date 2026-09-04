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

  @ObservationIgnored private var generation = UUID()

  public init() {}

  public func activate(account: ActiveAccount) async {
    generation = UUID()

    let generation = generation
    let previousClient = context?.client
    context = nil

    await previousClient?.resetEventSub()

    guard !Task.isCancelled, self.generation == generation else { return }

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
    generation = UUID()

    let previousClient = context?.client
    context = nil

    await previousClient?.resetEventSub()
  }
}
