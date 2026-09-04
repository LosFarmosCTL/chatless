public enum ChatConnectionStatus: Equatable, Sendable {
  case idle
  case connecting
  case connected
  case reconnecting(String)
  case failed(String)
}
