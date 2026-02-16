// swift-tools-version:6.2

import Foundation
import PackageDescription

#if TUIST
  import ProjectDescription
  import ProjectDescriptionHelpers

  let packageSettings = PackageSettings(
    productTypes: [
      "Twitch": .framework
    ],
    targetSettings: [
      "Twitch": .settings(base: baseTargetSettings)
    ]
  )
#endif

private let twitchClientURL = "https://github.com/LosFarmosCTL/swift-twitch-client"
private let twitchClientLocalPath = ProcessInfo.processInfo.environment["SWIFT_TWITCH_CLIENT_PATH"]
private let twitchClient: PackageDescription.Package.Dependency =
  if let twitchClientLocalPath {
    .package(path: twitchClientLocalPath)
  } else {
    .package(url: twitchClientURL, branch: "main")
  }

let package = PackageDescription.Package(
  name: "Chatless",
  dependencies: [
    twitchClient
  ],
)
