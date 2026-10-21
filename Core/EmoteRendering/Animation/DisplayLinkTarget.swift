import QuartzCore

@MainActor
final class DisplayLinkTarget {
  weak var driver: DisplayLinkDriver?

  @objc func tick(_ link: CADisplayLink) {
    driver?.displayLinkDidFire(link)
  }
}
