import SwiftUI
import Twitch

@MainActor
@Observable public final class TwitchAPIService {
  public enum Error: LocalizedError {
    case notAuthenticated

    public var errorDescription: String? {
      switch self {
      case .notAuthenticated:
        return "No authenticated Twitch client is available."
      }
    }
  }

  private let twitchClientStore: TwitchClientStore
  public init(twitchClientStore: TwitchClientStore) {
    self.twitchClientStore = twitchClientStore
  }

  public func withClient<Response>(
    _ request: (TwitchClient) async throws -> Response
  ) async throws -> Response {
    guard let client = twitchClientStore.context?.client else {
      throw Error.notAuthenticated
    }

    return try await request(client)
  }

  public func request<R>(
    _ endpoint: HelixEndpoint<R, some Decodable, HelixEndpointResponseTypes.Normal>
  ) async throws -> R {
    guard let client = twitchClientStore.context?.client else { throw Error.notAuthenticated }

    return try await client.helix(endpoint: endpoint)
  }

  public func request<R>(
    _ endpoint: HelixEndpoint<R, some Decodable, HelixEndpointResponseTypes.Raw>
  ) async throws -> R {
    guard let client = twitchClientStore.context?.client else { throw Error.notAuthenticated }

    return try await client.helix(endpoint: endpoint)
  }

  public func request(
    _ endpoint: HelixEndpoint<Void, some Decodable, HelixEndpointResponseTypes.Void>
  ) async throws {
    guard let client = twitchClientStore.context?.client else { throw Error.notAuthenticated }

    try await client.helix(endpoint: endpoint)
  }
}
