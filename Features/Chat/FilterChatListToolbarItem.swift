import SwiftUI

public struct FilterChatListToolbarItem: ToolbarContent {
  public var placement: ToolbarItemPlacement
  public init(placement: ToolbarItemPlacement) {
    self.placement = placement
  }

  public var body: some ToolbarContent {
    ToolbarItem(placement: placement) {
      Button {
      } label: {
        Image(systemName: "line.3.horizontal.decrease")
      }
    }
  }
}
