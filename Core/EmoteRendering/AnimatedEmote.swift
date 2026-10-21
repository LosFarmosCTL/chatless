import Emotes
import SwiftUI

public struct AnimatedEmote: View {
  @Environment(EmotePlaybackCoordinator.self) private var coordinator
  @Environment(\.displayScale) private var displayScale
  @State private var consumerID = UUID()
  @State private var asset: EmoteAssetRecord?
  @State private var isVisible = false
  @State private var pointHeight: CGFloat = 0

  private let definition: EmoteDefinition
  private let quality: AnimatedEmoteQuality
  private let onAspectRatioChange: (CGFloat) -> Void

  public init(
    definition: EmoteDefinition,
    quality: AnimatedEmoteQuality = .automatic,
    onAspectRatioChange: @escaping (CGFloat) -> Void = { _ in }
  ) {
    self.definition = definition
    self.quality = quality
    self.onAspectRatioChange = onAspectRatioChange
  }

  public var body: some View {
    let state = isVisible && pointHeight > 0 ? asset?.state ?? .failed : .loading(aspectRatio: 1)
    coordinator.recordPresentation()

    return content(for: state)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .onGeometryChange(for: CGFloat.self) { geometry in
        geometry.size.height
      } action: { newHeight in
        pointHeight = newHeight
        updatePlayback()
      }
      .onAppear {
        isVisible = true
        updatePlayback()
      }
      .onChange(of: definition) { updatePlayback() }
      .onChange(of: quality) { updatePlayback() }
      .onChange(of: displayScale) { updatePlayback() }
      .onChange(of: state.decodedAspectRatio, initial: true) { _, aspectRatio in
        guard let aspectRatio else { return }

        onAspectRatioChange(aspectRatio)
      }
      .onDisappear {
        isVisible = false
        coordinator.consumers.set(.preview(consumerID), assets: nil, owner: consumerID)
      }
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(definition.name)
      .accessibilityValue(accessibilityValue(for: state))
  }

  @ViewBuilder private func content(for state: EmoteRenderState) -> some View {
    switch state {
    case .ready(let image, _):
      Image(uiImage: image)
        .resizable()
        .scaledToFit()
    case .loading:
      ProgressView()
    case .failed:
      Image(systemName: "exclamationmark.triangle")
        .foregroundStyle(.secondary)
    }
  }

  private func updatePlayback() {
    guard isVisible, pointHeight > 0 else { return }

    let pixelHeight = max(Int(ceil(pointHeight * displayScale)), 1)
    asset = EmoteAssetSelection(
      definition: definition, pixelHeight: pixelHeight,
      usesHighestScale: quality == .highestAvailable
    ).map { coordinator.asset(for: $0) }
    coordinator.consumers.set(
      .preview(consumerID), assets: asset.map { [$0] } ?? [], owner: consumerID)
  }

  private func accessibilityValue(for state: EmoteRenderState) -> Text {
    switch state {
    case .ready:
      Text("Emote")
    case .loading:
      Text("Loading")
    case .failed:
      Text("Failed to load")
    }
  }
}
