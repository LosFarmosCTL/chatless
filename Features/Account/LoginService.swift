import Auth
import AuthenticationServices
import SwiftUI
import Twitch

@MainActor
public final class LoginService: ObservableObject {
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

      let validatedToken = try await TwitchClient.validateToken(token: token)

      if let user = try await TwitchClient(
        authentication: .init(
          oAuth: token,
          clientID: validatedToken.clientID,
          userID: validatedToken.userID,
          userLogin: validatedToken.login)
      ).helix(endpoint: .getUsers(ids: [validatedToken.userID])).first {
        await auth.login(
          profile: .init(
            id: user.id,
            displayName: user.displayName,
            login: user.login,
            profileImageURL: user.profileImageUrl),
          token: .init(
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
