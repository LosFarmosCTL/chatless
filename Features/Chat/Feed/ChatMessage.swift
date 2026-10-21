import Emotes

struct ChatMessage: Hashable, Identifiable, Sendable {
  let source: IncomingChatMessage
  let content: ParsedEmoteMessage
  let isProvisional: Bool

  var id: String { source.id }
  var author: String {
    source.authorDisplayName.isEmpty ? source.authorLogin : source.authorDisplayName
  }

  var authorColorHex: String? { source.authorColorHex }
  var accessibilityText: String { "\(author): \(source.rawText)" }

  init(source: IncomingChatMessage, catalog: ChannelEmoteCatalog, parser: EmoteMessageParser) {
    self.source = source
    self.isProvisional = !catalog.isComplete
    self.content = parser.parse(
      fragments: source.emoteFragments, catalog: catalog
    )
  }
}
