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
          ]
        ]
      ),
      dependencies: [
        .target(name: "Onboarding"),
        .target(name: "Account"),
        .target(name: "Auth"),
      ],
      additionalSettings: [
        "ASSETCATALOG_COMPILER_APPICON_NAME": "Chatless",
        "ENABLE_ASSET_CATALOG_APP_INTENTS_GENERATION": "YES",

        "ENABLE_MODULE_VERIFIER": "NO",
      ]
    )
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
