import Foundation
@preconcurrency import SDWebImage
import UIKit
import os

@MainActor
final class EmoteFrameDecoder {
  enum RequestResult {
    case scheduled
    case duplicate
    case capacityExceeded
  }

  private final class Request {
    let key: FrameKey
    let provider: SDAnimatedImage
    var completion: ((UIImage?) -> Void)?

    init(key: FrameKey, provider: SDAnimatedImage, completion: @escaping (UIImage?) -> Void) {
      self.key = key
      self.provider = provider
      self.completion = completion
    }
  }

  private let scheduler = FrameDecodeScheduler()
  private let signpostLog = OSLog(subsystem: "app.chatless.Chatless", category: "EmoteRendering")
  private var queued: [EmoteRenderKey: Request] = [:]
  private var order: [EmoteRenderKey] = []
  private var running: Request?
  private var signpostID: OSSignpostID?
  // OperationQueue can finish an in-flight decode after cancellation.
  private var generation: UInt64 = 0

  private(set) var decodedFrameCount = 0
  private(set) var droppedFrameRequests = 0
  var pendingCount: Int { queued.count + (running == nil ? 0 : 1) }

  func request(
    key: FrameKey,
    provider: SDAnimatedImage,
    completion: @escaping (UIImage?) -> Void
  ) -> RequestResult {
    guard running?.key != key || running?.completion == nil else { return .duplicate }
    guard queued[key.asset]?.key != key else { return .duplicate }

    if queued[key.asset] == nil {
      guard pendingCount < 16 else {
        droppedFrameRequests += 1
        return .capacityExceeded
      }

      order.append(key.asset)
    }

    queued[key.asset] = Request(key: key, provider: provider, completion: completion)
    startNext()
    return .scheduled
  }

  func discardQueued(for asset: EmoteRenderKey) {
    queued.removeValue(forKey: asset)
    order.removeAll { $0 == asset }
  }

  func cancel(_ asset: EmoteRenderKey) {
    discardQueued(for: asset)

    if running?.key.asset == asset {
      running?.completion = nil
    }
  }

  func cancelAll() {
    generation &+= 1
    scheduler.cancelAll()
    queued.removeAll()
    order.removeAll()
    running = nil
    endSignpost()
  }

  private func startNext() {
    guard running == nil, order.isEmpty == false else { return }

    let asset = order.removeFirst()
    guard let request = queued.removeValue(forKey: asset) else { return }

    running = request
    let requestGeneration = generation
    let id = OSSignpostID(log: signpostLog)
    signpostID = id
    os_signpost(.begin, log: signpostLog, name: "FrameDecode", signpostID: id)

    scheduler.decode(provider: request.provider, frameIndex: request.key.index) {
      [weak self] image in
      guard let self, self.generation == requestGeneration else { return }

      self.endSignpost()
      self.running = nil

      if image != nil {
        self.decodedFrameCount += 1
      }

      request.completion?(image)
      self.startNext()
    }
  }

  private func endSignpost() {
    guard let signpostID else { return }

    os_signpost(.end, log: signpostLog, name: "FrameDecode", signpostID: signpostID)
    self.signpostID = nil
  }
}
