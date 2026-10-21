import Foundation

public struct EmoteOccurrence: Hashable, Sendable {
  public let base: EmoteDefinition
  public let overlays: [EmoteDefinition]

  public init(base: EmoteDefinition, overlays: [EmoteDefinition] = []) {
    self.base = base
    self.overlays = overlays
  }

  public var definitions: [EmoteDefinition] { [base] + overlays }
}

public enum EmoteMessageSegment: Hashable, Sendable {
  case text(String)
  case emote(EmoteOccurrence)
}

public struct ParsedEmoteMessage: Hashable, Sendable {
  public let segments: [EmoteMessageSegment]
  public let definitions: [EmoteDefinition]

  public init(segments: [EmoteMessageSegment]) {
    self.segments = segments
    let definitions = segments.flatMap { segment -> [EmoteDefinition] in
      guard case .emote(let occurrence) = segment else { return [] }

      return occurrence.definitions
    }

    var seen: Set<EmoteDefinition> = []
    self.definitions = definitions.filter { seen.insert($0).inserted }
  }
}

public enum EmoteSourceFragment: Hashable, Sendable {
  case text(String)
  case twitchEmote(name: String, id: String)
}
