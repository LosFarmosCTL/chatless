import Foundation
import Observation

@MainActor
@Observable
public final class AccessibilityPreferences {
  @ObservationIgnored
  private let defaults: UserDefaults

  public var animatedEmotes: AnimatedEmotePreference {
    didSet {
      defaults.set(animatedEmotes.rawValue, forKey: Self.animatedEmotesKey)
    }
  }

  public init(defaults: UserDefaults) {
    self.defaults = defaults
    self.animatedEmotes =
      defaults.string(forKey: Self.animatedEmotesKey)
      .flatMap(AnimatedEmotePreference.init(rawValue:))
      ?? .systemDefault
  }

  public func reset() {
    animatedEmotes = .systemDefault
  }

  private static let animatedEmotesKey = "preferences.accessibility.animatedEmotes"
}
