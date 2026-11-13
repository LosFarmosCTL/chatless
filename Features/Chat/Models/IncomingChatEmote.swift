public struct IncomingChatEmote: Hashable, Sendable {
  public let id: String
  public let name: String
  // Indices refer to the enclosing IncomingChatMessage.rawText.
  public let range: Range<String.Index>

  public init(id: String, name: String, range: Range<String.Index>) {
    self.id = id
    self.name = name
    self.range = range
  }
}
