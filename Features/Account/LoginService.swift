import Auth
import AuthenticationServices
import SwiftUI
import Twitch

@MainActor
@Observable public final class LoginService {
  private let auth: AuthenticationStore

  public init(auth: AuthenticationStore) {
    self.auth = auth
  }

  public func login(using webAuthenticationSession: WebAuthenticationSession) async {
    let state = TwitchAuthURL.generateState()
    let loginURL = TwitchAuthURL.loginURL(state: state)

    do {
      let resultURL = try await webAuthenticationSession.authenticate(
        using: loginURL,
        callbackURLScheme: "chatless-auth"
      )

      let token = try TwitchAuthURL.parseResult(
        from: resultURL,
        localState: state
      )

      let validatedToken = try await TwitchClient.validateAccessToken(accessToken: token)

      guard let identity = validatedToken.user else {
        throw TwitchAuthenticationError.userAccessTokenRequired
      }

      if let user = try await TwitchClient(
        credentials: validatedToken.credentials(accessToken: token)
      ).helix(for: .getUsers(userIDs: [identity.id])).value.first {
        await auth.activateAccount(
          profile: .init(
            id: user.id,
            displayName: user.displayName,
            login: user.login,
            profileImageURL: user.profileImageURL),
          with: AuthToken(
            clientID: validatedToken.clientID,
            accessToken: token,
            expirationDate: validatedToken.expiresIn.flatMap {
              Date(timeIntervalSinceNow: Double($0))
            }
          )
        )
      }
    } catch AuthError.stateMismatch {
      print("Security Error: The state returned did not match.")
    } catch {
      print("Auth failed: \(error.localizedDescription)")
    }
  }
}
