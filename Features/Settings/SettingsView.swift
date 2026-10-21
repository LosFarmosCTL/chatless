import Shared
import SwiftUI

public struct SettingsView: View {
  @Environment(AppPreferences.self) private var preferences

  public init() {}

  public var body: some View {
    NavigationStack {
      Form {
        AccessibilitySettingsSection(preferences: preferences.accessibility)
        ChatSettingsSection(preferences: preferences.chat)
      }
      .navigationTitle("Settings")
    }
  }
}
