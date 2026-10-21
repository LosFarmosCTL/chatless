struct EmotePlaybackPolicy {
  var isSceneActive = true
  var animatedEmotesEnabled = true

  var allowsAnimation: Bool { isSceneActive && animatedEmotesEnabled }
}
