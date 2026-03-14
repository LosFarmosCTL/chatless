import SwiftUI

@MainActor
@Observable public final class AppRouter {
  public var path: [AppRoute] = []

  public init() {}

  public func push(_ route: AppRoute) {
    path.append(route)
  }

  public func popToRoot() {
    path.removeAll()
  }
}
