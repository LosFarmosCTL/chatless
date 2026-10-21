import Foundation
import Observation

@MainActor
@Observable
public final class ChatPreferences {
  public static let emoteHeightRange = 12...40
  public static let defaultEmoteHeight = 20
  @ObservationIgnored
  private let defaults: UserDefaults

  public var showTimestamps: Bool {
    didSet {
      defaults.set(showTimestamps, forKey: Self.showTimestampsKey)
    }
  }

  public var emoteHeight: Int {
    didSet {
      emoteHeight = Self.clampedEmoteHeight(emoteHeight)
      defaults.set(emoteHeight, forKey: Self.emoteHeightKey)
    }
  }

  public init(defaults: UserDefaults) {
    self.defaults = defaults
    self.showTimestamps =
      defaults.object(forKey: Self.showTimestampsKey) as? Bool
      ?? true
    self.emoteHeight = Self.clampedEmoteHeight(
      defaults.object(forKey: Self.emoteHeightKey) as? Int ?? Self.defaultEmoteHeight
    )
  }

  public func reset() {
    showTimestamps = true
    emoteHeight = Self.defaultEmoteHeight
  }

  private static func clampedEmoteHeight(_ height: Int) -> Int {
    min(max(height, emoteHeightRange.lowerBound), emoteHeightRange.upperBound)
  }

  private static let showTimestampsKey = "preferences.chat.showTimestamps"
  private static let emoteHeightKey = "preferences.chat.emoteHeight"
}
