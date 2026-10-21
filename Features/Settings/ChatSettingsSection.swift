import Shared
import SwiftUI

struct ChatSettingsSection: View {
  @Bindable var preferences: ChatPreferences

  var body: some View {
    Section("Chat") {
      Toggle("Show Timestamps", isOn: $preferences.showTimestamps)

      Stepper(value: $preferences.emoteHeight, in: ChatPreferences.emoteHeightRange) {
        LabeledContent("Emote Size") {
          Text("\(preferences.emoteHeight) pt")
        }
      }
    }
  }
}
