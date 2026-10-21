import Foundation
import Observation
@preconcurrency import SDWebImage
import UIKit
import os

// Shared presentation identity. Only active demand retains decoded resources here.
@MainActor
@Observable final class EmoteAssetRecord {
  let selection: EmoteAssetSelection
  var state: EmoteRenderState = .loading(aspectRatio: 1)

  @ObservationIgnored var source: EmoteAssetSource?
  @ObservationIgnored var currentFrameIndex: Int?
  @ObservationIgnored var requestedFrameIndex: Int?
  @ObservationIgnored private var operation: SDWebImageCombinedOperation?
  @ObservationIgnored private var requestID: UUID?
  @ObservationIgnored private var signpostID: OSSignpostID?
  private static let log = OSLog(subsystem: "app.chatless.Chatless", category: "EmoteRendering")

  init(selection: EmoteAssetSelection) {
    self.selection = selection
  }

  isolated deinit {
    cancelLoad()
  }

  var currentImage: UIImage? {
    guard case .ready(let image, _) = state else { return nil }

    return image
  }

  var aspectRatio: CGFloat { source?.aspectRatio ?? state.aspectRatio ?? 1 }
  var timeline: FrameTimeline? { source?.timeline }
  var isAnimated: Bool { (timeline?.durations.count ?? 0) > 1 }
  var isLoading: Bool { requestID != nil }
  var isFailed: Bool {
    if case .failed = state { true } else { false }
  }

  func load(
    using loader: EmoteAssetLoader, completion: @escaping (EmoteAssetLoader.Outcome) -> Void
  ) {
    guard !isFailed, !isLoading else { return }

    let id = UUID()
    requestID = id
    let signpost = OSSignpostID(log: Self.log)
    signpostID = signpost
    os_signpost(.begin, log: Self.log, name: "EmoteDownload", signpostID: signpost)

    operation = loader.load(selection) { [weak self] outcome in
      guard let self, requestID == id else { return }

      finishRequest()
      completion(outcome)
    }
  }

  func cancelLoad() {
    let previous = operation
    finishRequest()
    previous?.cancel()
  }

  func releaseResources(preservingFailure: Bool = false) {
    let ratio = aspectRatio
    let failed = preservingFailure && isFailed
    source = nil
    currentFrameIndex = nil
    requestedFrameIndex = nil
    state = failed ? .failed : .loading(aspectRatio: ratio)
  }

  private func finishRequest() {
    requestID = nil
    operation = nil

    if let signpostID {
      os_signpost(.end, log: Self.log, name: "EmoteDownload", signpostID: signpostID)
      self.signpostID = nil
    }
  }
}
