import CryptoKit
import Foundation

public enum TwitchAuthURL {
  public static var clientID: String {
    Bundle.main.infoDictionary?["TwitchClientID"] as? String ?? ""
  }

  private static var redirectURI: String {
    let scheme = Bundle.main.infoDictionary?["TwitchRedirectURIScheme"] as? String ?? ""
    let host = Bundle.main.infoDictionary?["TwitchRedirectURIHost"] as? String ?? ""

    return "\(scheme)://\(host)"
  }

  private static var scopes: String {
    Bundle.main.infoDictionary?["TwitchScopes"] as? String ?? ""
  }

  public static func generateState() -> String {
    let data = AES.GCM.Nonce()  // 12 random bytes is standard
    return data.withUnsafeBytes {
      $0.map { String(format: "%02hhx", $0) }.joined()
    }
  }

  public static func loginURL(state: String) -> URL {
    var components = URLComponents()

    components.scheme = "https"
    components.host = "id.twitch.tv"
    components.path = "/oauth2/authorize"
    components.queryItems = [
      URLQueryItem(name: "response_type", value: "token"),
      URLQueryItem(name: "client_id", value: clientID),
      URLQueryItem(name: "scope", value: scopes),
      URLQueryItem(name: "redirect_uri", value: redirectURI),
      URLQueryItem(name: "state", value: state),
      URLQueryItem(name: "force_verify", value: "true"),
    ]

    return components.url!
  }

  public static func parseResult(from url: URL, localState: String) throws -> String {
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
      let queryItems = components.queryItems
    else {
      throw AuthError.invalidResponse
    }

    let accessToken = queryItems.first(where: { $0.name == "access_token" })?.value
    let returnedState = queryItems.first(where: { $0.name == "state" })?.value

    guard returnedState == localState else {
      throw AuthError.stateMismatch
    }

    guard let token = accessToken else {
      throw AuthError.missingToken
    }

    return token
  }
}

public enum AuthError: Error {
  case invalidResponse
  case stateMismatch
  case missingToken
}
