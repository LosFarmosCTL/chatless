import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
  name: "Chatless",
  options: .options(
    disableBundleAccessors: true,
    textSettings: .textSettings(usesTabs: false, indentWidth: 2, tabWidth: 2)),
  packages: [
    .remote(
      url: "https://github.com/SimplyDanny/SwiftLintPlugins",
      requirement: .upToNextMajor(from: "0.63.1")
    )
  ],
  settings: .settings(base: [
    "DEVELOPMENT_TEAM": "AD35535HSK",

    "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES",
    "STRING_CATALOG_GENERATE_SYMBOLS": "YES",
  ]),
  targets: [
    // MARK: App Target

    .module(
      name: "Chatless",
      product: .app,
      bundleId: "app.chatless.Chatless",
      sources: ["App/**/*.swift"],
      resources: [
        .glob(
          pattern: "App/Resources/**",
          excluding: ["App/Resources/Chatless.icon/**"]),
        .glob(pattern: "App/Resources/Chatless.icon", excluding: []),
      ],
      infoPlist: .extendingDefault(
        with: [
          "UILaunchScreen": [
            "UIColorName": "",
            "UIImageName": "",
          ],
          "TwitchClientID": "$(TWITCH_CLIENT_ID)",
          "TwitchRedirectURIScheme": "$(TWITCH_REDIRECT_URI_SCHEME)",
          "TwitchRedirectURIHost": "$(TWITCH_REDIRECT_URI_HOST)",
          "TwitchScopes": "$(TWITCH_SCOPES)",
          "CFBundleURLTypes": [
            [
              "CFBundleURLName": "chatless-auth",
              "CFBundleURLSchemes": ["chatless-auth"],
            ]
          ],
        ]
      ),
      dependencies: [
        .target(name: "Auth"),
        .target(name: "TwitchSession"),

        .target(name: "Account"),
        .target(name: "Chat"),
      ],
      additionalSettings: [
        "ASSETCATALOG_COMPILER_APPICON_NAME": "Chatless",
        "ENABLE_ASSET_CATALOG_APP_INTENTS_GENERATION": "YES",

        "ENABLE_MODULE_VERIFIER": "NO",
      ],
      xcconfig: "App.xcconfig"
    ),

    // MARK: Core Targets

    .module(
      name: "Auth",
      bundleId: "app.chatless.Chatless.Auth",
      sources: ["Core/Auth/**/*.swift"],
    ),
    .module(
      name: "TwitchSession",
      bundleId: "app.chatless.Chatless.TwitchSession",
      sources: ["Core/TwitchSession/**/*.swift"],
    ),

    // MARK: Feature Targets

    .module(
      name: "Account",
      bundleId: "app.chatless.Chatless.Account",
      sources: ["Features/Account/**/*.swift"],
      resources: ["Resources/Account/**"],
      dependencies: [
        .target(name: "Auth")
      ]
    ),
    .module(
      name: "Chat",
      bundleId: "app.chatless.Chatless.Chat",
      sources: ["Features/Chat/**/*.swift"],
      resources: ["Resources/Chat/**"],
      dependencies: [
        .target(name: "TwitchSession"),
        .target(name: "Auth"),
      ]
    ),
  ],
  additionalFiles: [
    "README.md",
    "LICENSE",
    ".gitignore",
    ".swiftlint.yml",
    ".swift-format",
  ],
  resourceSynthesizers: [],
)
