import Emotes
import Observation

@MainActor
@Observable final class ChatFeedStore {
  private(set) var messages: [ChatMessage] = []
  private(set) var catalog: ChannelEmoteCatalog
  @ObservationIgnored private let parser = EmoteMessageParser()
  @ObservationIgnored private var messageIDs: Set<String> = []
  private static let historyLimit = 1_000

  init(channelID: String) {
    catalog = ChannelEmoteCatalog(channelID: channelID)
  }

  func receive(_ source: IncomingChatMessage) {
    guard source.channelID == catalog.channelID, messageIDs.insert(source.id).inserted else {
      return
    }

    messages.append(makeMessage(source))

    if messages.count > Self.historyLimit {
      messageIDs.remove(messages.removeFirst().id)
    }
  }

  func apply(_ update: EmoteCatalogUpdate) {
    guard update.catalog.channelID == catalog.channelID else { return }

    let previous = catalog
    catalog = update.catalog

    guard
      update.reason == .reconciliation || previous.definitionsByName != catalog.definitionsByName
        || previous.isComplete != catalog.isComplete
    else { return }

    // Preserve receipt-time interpretation on ordinary live changes. Reconciliation
    // intentionally follows the historical policy agreed in the architecture review.
    for index in messages.indices
    where messages[index].isProvisional || update.reason == .reconciliation {
      let replacement = makeMessage(messages[index].source)

      if messages[index] != replacement {
        messages[index] = replacement
      }
    }
  }

  private func makeMessage(_ source: IncomingChatMessage) -> ChatMessage {
    ChatMessage(source: source, catalog: catalog, parser: parser)
  }
}
