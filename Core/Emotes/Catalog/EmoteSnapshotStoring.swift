protocol EmoteSnapshotStoring: Actor {
  func loadAll() -> [ProviderCatalogSnapshot]
  func save(_ snapshot: ProviderCatalogSnapshot)
}
