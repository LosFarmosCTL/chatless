import Foundation
import Observation

@MainActor
@Observable
public final class AppPreferences {
  public let accessibility: AccessibilityPreferences
  public let chat: ChatPreferences

  public init(defaults: UserDefaults = .standard) {
    self.accessibility = AccessibilityPreferences(defaults: defaults)
    self.chat = ChatPreferences(defaults: defaults)
  }
}
