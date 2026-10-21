import Foundation

struct SevenTVLiveSocket: Sendable {
  enum Failure: Error {
    case invalidHello
    case closed
    case heartbeatTimedOut
  }

  let subscriptionLimit: Int
  private let socket: URLSessionWebSocketTask
  private let heartbeatTimeout: Duration

  static func open(endpoint: URL) async throws -> Self {
    let socket = URLSession.shared.webSocketTask(with: endpoint)
    socket.resume()

    do {
      let message = try await receive(from: socket, timeout: .seconds(20))
      guard let data = EmoteWebSocketSupport.data(from: message),
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
        let payload = object["d"] as? [String: Any],
        let limit = payload["subscription_limit"] as? Int, limit > 0,
        let heartbeat = payload["heartbeat_interval"] as? Int, heartbeat > 0
      else { throw Failure.invalidHello }

      return Self(
        subscriptionLimit: limit,
        socket: socket,
        heartbeatTimeout: .milliseconds(max(heartbeat * 2, 10_000))
      )
    } catch {
      socket.cancel(with: .goingAway, reason: nil)
      throw error
    }
  }

  func close() {
    socket.cancel(with: .goingAway, reason: nil)
  }

  func subscribe(_ subscriptions: [SevenTVSubscription]) async throws {
    for subscription in subscriptions {
      let command = SubscribeCommand(
        operation: 35,
        data: SubscribeData(
          type: subscription.key.eventType,
          condition: SubscribeCondition(objectID: subscription.key.objectID)
        )
      )
      try await socket.send(.data(try JSONEncoder().encode(command)))
    }
  }

  func consume(
    subscriptions: [SevenTVSubscription],
    onEvent: @escaping @Sendable (EmoteLiveEvent) async -> Void
  ) async throws {
    defer { close() }
    let routes = Dictionary(uniqueKeysWithValues: subscriptions.map { ($0.key, $0.channelIDs) })

    while !Task.isCancelled {
      let message = try await Self.receive(from: socket, timeout: heartbeatTimeout)
      try await dispatch(message, routes: routes, onEvent: onEvent)
    }
  }

  private func dispatch(
    _ message: URLSessionWebSocketTask.Message,
    routes: [SevenTVSubscription.Key: Set<String?>],
    onEvent: @escaping @Sendable (EmoteLiveEvent) async -> Void
  ) async throws {
    guard let data = EmoteWebSocketSupport.data(from: message),
      let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
      let payload = object["d"] as? [String: Any]
    else { return }

    let operation = object["op"] as? Int

    if operation == 4 || operation == 7 { throw Failure.closed }
    if operation == 6 { throw Failure.invalidHello }
    guard operation == 0, let type = payload["type"] as? String else { return }

    let body = payload["body"] as? [String: Any]
    guard let id = body?["id"] as? String,
      let channels = routes[.init(eventType: type, objectID: id)]
    else {
      await onEvent(.changed(.provider))
      return
    }

    // A shared set may supply both global and channel scopes.
    for channelID in channels {
      await onEvent(.changed(channelID.map(EmoteInvalidationScope.channel) ?? .global))
    }
  }

  private static func receive(
    from socket: URLSessionWebSocketTask,
    timeout: Duration
  ) async throws -> URLSessionWebSocketTask.Message {
    try await withThrowingTaskGroup(of: URLSessionWebSocketTask.Message.self) { group in
      group.addTask { try await EmoteWebSocketSupport.receive(from: socket) }
      group.addTask {
        try await Task.sleep(for: timeout)
        socket.cancel(with: .goingAway, reason: nil)
        throw Failure.heartbeatTimedOut
      }

      defer { group.cancelAll() }
      guard let message = try await group.next() else { throw Failure.closed }
      return message
    }
  }

  private struct SubscribeCommand: Encodable {
    let operation: Int
    let data: SubscribeData

    enum CodingKeys: String, CodingKey {
      case operation = "op"
      case data = "d"
    }
  }

  private struct SubscribeData: Encodable {
    let type: String
    let condition: SubscribeCondition
  }

  private struct SubscribeCondition: Encodable {
    let objectID: String

    enum CodingKeys: String, CodingKey {
      case objectID = "object_id"
    }
  }
}
