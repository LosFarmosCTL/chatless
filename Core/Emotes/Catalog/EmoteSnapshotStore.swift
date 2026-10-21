import Foundation

actor EmoteSnapshotStore: EmoteSnapshotStoring {
  private let directory: URL
  private let byteLimit = 16 * 1_024 * 1_024
  private let encoder: JSONEncoder
  private let decoder: JSONDecoder

  init(fileManager: FileManager = .default) {
    let caches =
      fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
      ?? fileManager.temporaryDirectory
    directory = caches.appendingPathComponent("EmoteCatalogs", isDirectory: true)
    try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

    encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .millisecondsSince1970
    decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .millisecondsSince1970
  }

  func loadAll() -> [ProviderCatalogSnapshot] {
    let keys: Set<URLResourceKey> = [.isRegularFileKey]

    guard
      let urls = try? FileManager.default.contentsOfDirectory(
        at: directory,
        includingPropertiesForKeys: Array(keys),
        options: [.skipsHiddenFiles]
      )
    else { return [] }

    return urls.compactMap { url in
      guard url.pathExtension == "json", let data = try? Data(contentsOf: url) else { return nil }

      return try? decoder.decode(ProviderCatalogSnapshot.self, from: data)
    }
  }

  func save(_ snapshot: ProviderCatalogSnapshot) {
    guard let data = try? encoder.encode(snapshot) else { return }

    let url = directory.appendingPathComponent(snapshot.key.filename)

    do {
      try data.write(to: url, options: .atomic)
      try trimIfNeeded()
    } catch {
      return
    }
  }

  private func trimIfNeeded() throws {
    let keys: Set<URLResourceKey> = [.fileSizeKey, .contentModificationDateKey]
    let urls = try FileManager.default.contentsOfDirectory(
      at: directory,
      includingPropertiesForKeys: Array(keys),
      options: [.skipsHiddenFiles]
    )
    var entries = urls.compactMap { url -> (URL, Int, Date)? in
      guard let values = try? url.resourceValues(forKeys: keys) else { return nil }

      return (url, values.fileSize ?? 0, values.contentModificationDate ?? .distantPast)
    }

    var total = entries.reduce(0) { $0 + $1.1 }

    guard total > byteLimit else { return }

    entries.sort { $0.2 < $1.2 }

    for entry in entries where total > byteLimit {
      try? FileManager.default.removeItem(at: entry.0)
      total -= entry.1
    }
  }
}
