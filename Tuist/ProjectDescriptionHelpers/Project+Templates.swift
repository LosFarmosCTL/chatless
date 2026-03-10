import ProjectDescription

public let baseTargetSettings: SettingsDictionary = [
  "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
  "ENABLE_MODULE_VERIFIER": "YES",
  "MODULE_VERIFIER_SUPPORTED_LANGUAGE_STANDARDS": "gnu11 gnu++14",

  "LOCALIZATION_PREFERS_STRING_CATALOGS": "YES",
  "SWIFT_EMIT_LOC_STRINGS": "YES",
]

private func productType() -> Product {
  if case .string(let linking) = Environment.linking, linking == "static" {
    .staticFramework
  } else {
    .framework
  }
}

extension Target {
  public static func module(
    name: String,
    product: Product? = nil,
    bundleId: String,
    sources: SourceFilesList,
    resources: ResourceFileElements? = nil,
    infoPlist: InfoPlist = .default,
    dependencies: [TargetDependency] = [],
    additionalSettings: SettingsDictionary = [:],
    xcconfig: Path? = nil,
    includeShared: Bool = true
  ) -> Target {
    let mergedSettings = baseTargetSettings.merging(additionalSettings) { _, new in new }
    var mergedDependencies: [TargetDependency] = [
      .package(product: "SwiftLintBuildToolPlugin", type: .plugin),
      .external(name: "Twitch"),
    ]

    if includeShared {
      mergedDependencies.append(.target(name: "Shared"))
    }

    mergedDependencies += dependencies

    return Target.target(
      name: name,
      destinations: .iOS,
      product: product ?? productType(),
      bundleId: bundleId,
      deploymentTargets: .iOS("26.0"),
      infoPlist: infoPlist,
      sources: sources,
      resources: resources,
      dependencies: mergedDependencies,
      settings: .settings(
        base: mergedSettings,
        configurations: xcconfig != nil
          ? [
            .debug(name: .debug, xcconfig: xcconfig),
            .release(name: .release, xcconfig: xcconfig),
          ] : []))
  }

  public static func testModule(
    name: String,
    bundleId: String,
    sources: SourceFilesList,
    dependencies: [TargetDependency]
  ) -> Target {
    Target.target(
      name: name,
      destinations: .iOS,
      product: .unitTests,
      bundleId: bundleId,
      deploymentTargets: .iOS("26.0"),
      infoPlist: .default,
      sources: sources,
      dependencies: dependencies,
      settings: .settings(base: [
        "SWIFT_EMIT_LOC_STRINGS": "NO"
      ])
    )
  }
}
