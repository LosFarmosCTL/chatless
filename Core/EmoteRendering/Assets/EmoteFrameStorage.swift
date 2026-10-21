@preconcurrency import SDWebImage
import UIKit

@MainActor
final class EmoteFrameStorage {
  private struct Reference {
    weak var record: EmoteAssetRecord?
  }

  private var references: [EmoteRenderKey: Reference] = [:]
  private let frameBudget: Int
  private let sourceBudget: Int
  private var frames: CostLRUCache<FrameKey, UIImage>
  private var sources: CostLRUCache<EmoteRenderKey, EmoteAssetSource>
  private var records: [EmoteRenderKey: EmoteAssetRecord] = [:]
  private var activeFrameBytes = 0
  private var activeSourceBytes = 0

  init(frameBudget: Int = 128 * 1_024 * 1_024, sourceBudget: Int = 16 * 1_024 * 1_024) {
    self.frameBudget = frameBudget
    self.sourceBudget = sourceBudget
    frames = CostLRUCache(costLimit: frameBudget)
    sources = CostLRUCache(costLimit: sourceBudget)
  }

  var cacheEvictions: Int { frames.evictionCount + sources.evictionCount }
  var decodedBytes: Int { activeFrameBytes + frames.totalCost }
  var pinnedDecodedBytes: Int { activeFrameBytes }
  var providerBytes: Int { activeSourceBytes + sources.totalCost }

  var active: Dictionary<EmoteRenderKey, EmoteAssetRecord>.Values { records.values }
  var activeKeys: Set<EmoteRenderKey> { Set(records.keys) }

  func asset(for selection: EmoteAssetSelection) -> EmoteAssetRecord {
    if let record = references[selection.key]?.record { return record }

    let record = EmoteAssetRecord(selection: selection)
    references[selection.key] = Reference(record: record)

    return record
  }

  func pruneReferences() {
    references = references.filter { $0.value.record != nil }
  }

  func activate(_ record: EmoteAssetRecord) {
    let asset = record.selection.key
    guard records[asset] == nil else { return }

    record.source = sources.take(asset)
    activeSourceBytes += record.source?.cost ?? 0
    records[asset] = record

    if let source = record.source, record.state.aspectRatio != source.aspectRatio {
      record.state = .loading(aspectRatio: source.aspectRatio)
    }

    if let poster = frames.take(FrameKey(asset: asset, index: 0)) {
      replaceCurrentFrame(poster, asset: asset, index: 0)
    }

    updateBudgets()
  }

  func deactivate(_ asset: EmoteRenderKey) {
    guard let record = records.removeValue(forKey: asset) else { return }

    record.cancelLoad()
    activeFrameBytes -= record.currentImage.map(imageCost) ?? 0
    activeSourceBytes -= record.source?.cost ?? 0
    updateBudgets()

    if let source = record.source {
      sources.insert(source, for: asset, cost: max(source.cost, 1))
    }

    if let image = record.currentImage, let index = record.currentFrameIndex {
      frames.insert(image, for: FrameKey(asset: asset, index: index), cost: imageCost(image))
    }

    record.releaseResources()
  }

  func record(for asset: EmoteRenderKey) -> EmoteAssetRecord? { records[asset] }

  func takeFrame(for key: FrameKey) -> UIImage? { frames.take(key) }

  func cacheFrame(_ image: UIImage, for key: FrameKey) {
    guard records[key.asset]?.currentFrameIndex != key.index,
      records[key.asset]?.currentImage !== image
    else { return }

    frames.insert(image, for: key, cost: imageCost(image))
  }

  func install(_ image: UIImage, encodedData: Data?, asset: EmoteRenderKey) {
    guard let record = records[asset] else { return }

    activeSourceBytes -= record.source?.cost ?? 0
    record.source = EmoteAssetSource(image: image, encodedData: encodedData)
    activeSourceBytes += record.source?.cost ?? 0

    // A poster is a decoded frame, never the animation provider itself.
    let poster =
      image.cgImage.map {
        UIImage(cgImage: $0, scale: image.scale, orientation: image.imageOrientation)
      } ?? image
    replaceCurrentFrame(poster, asset: asset, index: 0)
    updateBudgets()
  }

  @discardableResult
  func replaceCurrentFrame(_ image: UIImage, asset: EmoteRenderKey, index: Int) -> Bool {
    guard let record = records[asset] else { return false }
    guard record.currentFrameIndex != index || record.currentImage !== image else { return false }

    let previousImage = record.currentImage
    let previousIndex = record.currentFrameIndex
    activeFrameBytes += imageCost(image) - (previousImage.map(imageCost) ?? 0)
    record.state = .ready(image: image, aspectRatio: record.aspectRatio)
    record.currentFrameIndex = index
    _ = frames.take(FrameKey(asset: asset, index: index))
    updateBudgets()

    if let previousImage, previousImage !== image, let previousIndex, previousIndex != index {
      cacheFrame(previousImage, for: FrameKey(asset: asset, index: previousIndex))
    }

    return true
  }

  func clearAll() {
    clearReusable()

    for record in records.values {
      record.releaseResources(preservingFailure: true)
    }

    activeFrameBytes = 0
    activeSourceBytes = 0
    updateBudgets()
  }

  func clearReusable() {
    frames.removeAll()
    sources.removeAll()
  }

  private func updateBudgets() {
    frames.setCostLimit(frameBudget - activeFrameBytes)
    sources.setCostLimit(sourceBudget - activeSourceBytes)
  }

  private func imageCost(_ image: UIImage) -> Int {
    guard let cgImage = image.cgImage else {
      return Int(image.size.width * image.size.height * image.scale * image.scale * 4)
    }

    return cgImage.bytesPerRow * cgImage.height
  }
}
