public struct IncomingChatEmote: Hashable, Sendable {
  public let id: String
  public let name: String
  public let range: Range<Int>

  public init(id: String, name: String, range: Range<Int>) {
    self.id = id
    self.name = name
    self.range = range
  }
}
