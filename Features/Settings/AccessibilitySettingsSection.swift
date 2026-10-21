import Shared
import SwiftUI

struct AccessibilitySettingsSection: View {
  @Bindable var preferences: AccessibilityPreferences

  var body: some View {
    Section("Accessibility") {
      Picker("Animated Emotes", selection: $preferences.animatedEmotes) {
        Text("System Default")
          .tag(AnimatedEmotePreference.systemDefault)
        Text("Always")
          .tag(AnimatedEmotePreference.always)
        Text("Never")
          .tag(AnimatedEmotePreference.never)
      }
    }
  }
}
