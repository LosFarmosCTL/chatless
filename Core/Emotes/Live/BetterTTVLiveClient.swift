import Foundation

struct BetterTTVLiveClient: Sendable {
  private let endpoint = URL(string: "wss://sockets.betterttv.net/ws")!

  func run(
    channels: Set<String>,
    onEvent: @escaping @Sendable (EmoteLiveEvent) async -> Void
  ) async {
    var attempt = 0
    var hasConnected = false

    while Task.isCancelled == false {
      do {
        let socket = URLSession.shared.webSocketTask(with: endpoint)
        socket.resume()
        defer { socket.cancel(with: .goingAway, reason: nil) }

        for channelID in channels.sorted() {
          let command = Command(
            name: "join_channel",
            data: ["name": "twitch:\(channelID)"]
          )
          try await socket.send(.data(try JSONEncoder().encode(command)))
        }

        attempt = 0

        if hasConnected {
          await onEvent(.reconnected)
        }

        hasConnected = true

        while Task.isCancelled == false {
          let message = try await EmoteWebSocketSupport.receive(from: socket)

          guard let data = EmoteWebSocketSupport.data(from: message),
            let envelope = try? JSONDecoder().decode(EventEnvelope.self, from: data),
            ["emote_create", "emote_update", "emote_delete"].contains(envelope.name)
          else { continue }

          let prefix = "twitch:"
          let channelID =
            envelope.data.channel.hasPrefix(prefix)
            ? String(envelope.data.channel.dropFirst(prefix.count))
            : nil
          await onEvent(.changed(channelID.map(EmoteInvalidationScope.channel) ?? .provider))
        }
      } catch is CancellationError {
        return
      } catch {
        attempt += 1
        try? await Task.sleep(for: EmoteWebSocketSupport.reconnectDelay(attempt: attempt))
      }
    }
  }

  private struct Command: Encodable {
    let name: String
    let data: [String: String]
  }

  private struct EventEnvelope: Decodable {
    let name: String
    let data: EventData
  }

  private struct EventData: Decodable {
    let channel: String
  }
}
