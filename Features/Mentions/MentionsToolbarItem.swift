import SwiftUI

public struct MentionsToolbarItem: ToolbarContent {
  public var placement: ToolbarItemPlacement
  @Binding public var showingMentions: Bool

  public init(placement: ToolbarItemPlacement, showingMentions: Binding<Bool>) {
    self.placement = placement
    self._showingMentions = showingMentions
  }

  public var body: some ToolbarContent {
    ToolbarItem(id: "mentions", placement: placement) {
      Button {
        showingMentions = true
      } label: {
        Image(systemName: "bell.badge")
          .foregroundStyle(.red, .primary)
      }
    }
  }
}
