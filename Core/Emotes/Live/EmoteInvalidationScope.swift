enum EmoteInvalidationScope: Sendable {
  case global
  case channel(String)
  case provider
}
