import Foundation

struct FrameTimeline: Sendable {
  let durations: [TimeInterval]
  private let frameEndTimes: [TimeInterval]
  let totalDuration: TimeInterval

  init(durations: [TimeInterval]) {
    self.durations = durations.map { $0 > 0 ? $0 : 0.1 }
    var total: TimeInterval = 0
    frameEndTimes = self.durations.map { duration in
      total += duration

      return total
    }

    totalDuration = total
  }

  func frameIndex(at elapsed: TimeInterval) -> Int {
    guard frameEndTimes.count > 1, totalDuration > 0 else { return 0 }

    let phase = elapsed.truncatingRemainder(dividingBy: totalDuration)
    var lower = 0
    var upper = frameEndTimes.count

    while lower < upper {
      let middle = (lower + upper) / 2

      if phase < frameEndTimes[middle] {
        upper = middle
      } else {
        lower = middle + 1
      }
    }

    return min(lower, frameEndTimes.count - 1)
  }
}
