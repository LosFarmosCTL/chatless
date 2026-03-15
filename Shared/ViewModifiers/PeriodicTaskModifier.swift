import SwiftUI

public struct PeriodicTaskModifier: ViewModifier {
  let duration: Duration

  @Binding var isBusy: Bool
  let action: @Sendable () async -> Void

  public func body(content: Content) -> some View {
    content.task {
      while !Task.isCancelled {
        isBusy = true
        await action()
        isBusy = false

        try? await Task.sleep(for: duration)
      }
    }
  }
}

extension View {
  public func task(
    every duration: Duration,
    isBusy: Binding<Bool> = .constant(false),
    _ action: @escaping @Sendable () async -> Void
  ) -> some View {
    self.modifier(
      PeriodicTaskModifier(
        duration: duration,
        isBusy: isBusy,
        action: action))
  }
}
