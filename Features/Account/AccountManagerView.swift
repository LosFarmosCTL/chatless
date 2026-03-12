import Auth
import SwiftUI

public struct AccountManagerView: View {
  @Environment(\.webAuthenticationSession) private var webAuthenticationSession

  @Environment(AuthenticationStore.self) private var auth
  @Environment(LoginService.self) private var loginService

  public init() {}

  public var body: some View {
    VStack(spacing: 16) {
      switch auth.state {
      case .none:
        Text("You must be signed in to use Chatless.")
      case .active:
        EmptyView()
      case .expired(let profile):
        Text(
          "Your previous session for \(profile.displayName) expired. Sign in again to continue."
        )
      }

      Button("Sign In") {
        Task { await loginService.login(using: webAuthenticationSession) }
      }
    }
  }
}
