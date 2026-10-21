import Emotes
import SwiftUI

public struct EmoteDetailSheet: View {
  @ScaledMetric(relativeTo: .body) private var linkedChromeHeight = 168.0
  @ScaledMetric(relativeTo: .body) private var unlinkedChromeHeight = 94.0
  @State private var decodedAspectRatio: CGFloat?

  private let emote: EmoteDefinition

  public init(emote: EmoteDefinition) {
    self.emote = emote
  }

  public var body: some View {
    VStack(spacing: contentSpacing) {
      AnimatedEmote(
        definition: emote,
        quality: .highestAvailable,
        onAspectRatioChange: updateAspectRatio
      )
      .controlSize(.large)
      .frame(width: previewSize.width, height: previewSize.height)

      VStack(spacing: 3) {
        Text(emote.name)
          .font(.title2.bold())
        Text("\(emote.id.provider.displayName) emote")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }

      if let detailURL {
        Link(destination: detailURL) {
          Label("View on \(emote.id.provider.displayName)", systemImage: "safari")
        }
        .buttonStyle(.borderedProminent)
      }
    }
    .frame(maxWidth: .infinity)
    .padding(contentPadding)
    .presentationDetents([.height(detentHeight)])
  }

  private var detailURL: URL? {
    emote.id.provider.detailURL(for: emote.id.value, named: emote.name)
  }

  private var previewSize: CGSize {
    if previewAspectRatio >= 1 {
      return CGSize(width: 150, height: 150 / previewAspectRatio)
    }

    return CGSize(width: 150 * previewAspectRatio, height: 150)
  }

  private var previewAspectRatio: CGFloat {
    if let decodedAspectRatio {
      return decodedAspectRatio
    }

    guard let variant = emote.variants.last else { return 1 }

    return CGFloat(variant.pixelWidth) / CGFloat(variant.pixelHeight)
  }

  private var contentSpacing: CGFloat { detailURL == nil ? 12 : 18 }
  private var contentPadding: CGFloat { detailURL == nil ? 16 : 24 }

  private var detentHeight: CGFloat {
    previewSize.height + (detailURL == nil ? unlinkedChromeHeight : linkedChromeHeight)
  }

  private func updateAspectRatio(_ aspectRatio: CGFloat) {
    guard aspectRatio > 0, decodedAspectRatio != aspectRatio else { return }

    decodedAspectRatio = aspectRatio
  }
}
