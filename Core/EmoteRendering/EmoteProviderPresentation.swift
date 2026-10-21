import Emotes
import Foundation

extension EmoteProvider {
  var displayName: String {
    switch self {
    case .twitch: "Twitch"
    case .betterTTV: "BetterTTV"
    case .frankerFaceZ: "FrankerFaceZ"
    case .sevenTV: "7TV"
    }
  }

  func detailURL(for emoteID: String, named name: String) -> URL? {
    switch self {
    case .twitch:
      return nil
    case .betterTTV:
      return URL(string: "https://betterttv.com/emotes/\(emoteID)")
    case .frankerFaceZ:
      var components = URLComponents()
      components.scheme = "https"
      components.host = "www.frankerfacez.com"
      components.path = "/emoticon/\(emoteID)-\(name)"

      return components.url
    case .sevenTV:
      return URL(string: "https://7tv.app/emotes/\(emoteID)")
    }
  }
}
