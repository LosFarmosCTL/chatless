public enum AnimatedEmotePreference: String, CaseIterable, Identifiable {
  case systemDefault
  case always
  case never

  public var id: Self { self }
}
