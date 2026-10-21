import SwiftUI

extension View {
  func followsChatBottom(when latestEntryID: String?) -> some View {
    modifier(ChatBottomFollowingModifier(latestEntryID: latestEntryID))
  }
}

private struct ChatBottomFollowingModifier: ViewModifier {
  @State private var isFollowingBottom = true
  @State private var scrollPosition = ScrollPosition(idType: String.self, edge: .bottom)

  let latestEntryID: String?

  func body(content: Content) -> some View {
    content
      .defaultScrollAnchor(.bottom)
      .scrollPosition($scrollPosition)
      .onScrollGeometryChange(for: Bool.self) { geometry in
        geometry.visibleRect.maxY >= geometry.contentSize.height - 1
      } action: { _, isAtBottom in
        isFollowingBottom = isAtBottom
      }
      .onChange(of: latestEntryID) { oldID, newID in
        guard newID != nil, isFollowingBottom || oldID == nil else { return }

        scrollPosition.scrollTo(edge: .bottom)
      }
  }
}
