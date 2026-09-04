public enum EventSubscriptionStatus: Equatable {
  case idle
  case connecting
  case connected
  case reconnecting(String)
  case failed(String)
}
