import UIKit

enum EmoteRenderState {
  case loading(aspectRatio: CGFloat)
  case ready(image: UIImage, aspectRatio: CGFloat)
  case failed

  var aspectRatio: CGFloat? {
    switch self {
    case .loading(let aspectRatio), .ready(_, let aspectRatio):
      aspectRatio
    case .failed:
      nil
    }
  }

  var decodedAspectRatio: CGFloat? {
    guard case .ready(_, let aspectRatio) = self else { return nil }

    return aspectRatio
  }

  var layoutState: EmoteLayoutState {
    switch self {
    case .loading(let aspectRatio), .ready(_, let aspectRatio):
      .slot(aspectRatio: aspectRatio)
    case .failed:
      .failed
    }
  }
}

enum EmoteLayoutState: Equatable {
  case slot(aspectRatio: CGFloat)
  case failed
}
