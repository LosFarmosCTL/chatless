import Foundation

public struct EmoteMessageParser: Sendable {
  public init() {}

  public func parse(
    fragments: [EmoteSourceFragment],
    catalog: ChannelEmoteCatalog
  ) -> ParsedEmoteMessage {
    var segments: [EmoteMessageSegment] = []

    for fragment in fragments {
      switch fragment {
      case .text(let text):
        tokenize(text, catalog: catalog, into: &segments)
      case .twitchEmote(let name, let id):
        appendEmote(twitchDefinition(name: name, id: id), to: &segments)
      }
    }

    return ParsedEmoteMessage(segments: segments)
  }

  private func tokenize(
    _ text: String,
    catalog: ChannelEmoteCatalog,
    into segments: inout [EmoteMessageSegment]
  ) {
    guard let first = text.first else { return }

    var start = text.startIndex
    var isWhitespace = first.isWhitespace
    var index = text.index(after: start)

    while index < text.endIndex {
      let nextIsWhitespace = text[index].isWhitespace

      if nextIsWhitespace != isWhitespace {
        appendToken(
          String(text[start..<index]), isWhitespace: isWhitespace, catalog: catalog, to: &segments)
        start = index
        isWhitespace = nextIsWhitespace
      }

      index = text.index(after: index)
    }

    appendToken(
      String(text[start..<text.endIndex]), isWhitespace: isWhitespace, catalog: catalog,
      to: &segments)
  }

  private func appendToken(
    _ value: String,
    isWhitespace: Bool,
    catalog: ChannelEmoteCatalog,
    to segments: inout [EmoteMessageSegment]
  ) {
    guard isWhitespace == false, let definition = catalog.definition(named: value) else {
      appendText(value, to: &segments)

      return
    }

    appendEmote(definition, to: &segments)
  }

  private func appendText(_ value: String, to segments: inout [EmoteMessageSegment]) {
    guard value.isEmpty == false else { return }

    if case .text(let existing) = segments.last {
      segments[segments.count - 1] = .text(existing + value)
    } else {
      segments.append(.text(value))
    }
  }

  private func appendEmote(_ definition: EmoteDefinition, to segments: inout [EmoteMessageSegment])
  {
    if definition.isZeroWidth, segments.isEmpty == false {
      var baseIndex = segments.index(before: segments.endIndex)

      if case .text(let whitespace) = segments[baseIndex], whitespace.allSatisfy(\.isWhitespace) {
        guard baseIndex > segments.startIndex else {
          segments.append(.emote(EmoteOccurrence(base: definition)))

          return
        }

        baseIndex = segments.index(before: baseIndex)
      }

      if case .emote(let occurrence) = segments[baseIndex] {
        if segments.index(after: baseIndex) < segments.endIndex {
          segments.removeSubrange(segments.index(after: baseIndex)..<segments.endIndex)
        }

        segments[baseIndex] = .emote(
          EmoteOccurrence(base: occurrence.base, overlays: occurrence.overlays + [definition]))
        return
      }
    }

    segments.append(.emote(EmoteOccurrence(base: definition)))
  }

  private func twitchDefinition(name: String, id: String) -> EmoteDefinition {
    // IRC supplies no format metadata. Let the CDN select it and the decoder inspect frames.
    let variants = [("1.0", 28), ("2.0", 56), ("3.0", 112)].compactMap { scale, size in
      URL(string: "https://static-cdn.jtvnw.net/emoticons/v2/\(id)/default/dark/\(scale)").map {
        EmoteAssetVariant(
          url: $0,
          pixelWidth: size,
          pixelHeight: size
        )
      }
    }

    return EmoteDefinition(
      id: EmoteID(provider: .twitch, value: id),
      name: name,
      variants: variants
    )
  }
}
