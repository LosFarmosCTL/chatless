import Foundation
import SwiftUI

extension Color {
  /// Creates an sRGB color from RGB, RGBA, RRGGBB, or RRGGBBAA hexadecimal notation.
  public init?(hex value: String) {
    let value = value.trimmingCharacters(in: .whitespacesAndNewlines)
    let hex = value.hasPrefix("#") ? String(value.dropFirst()) : value

    guard
      hex.utf8.allSatisfy({
        (48...57).contains($0) || (65...70).contains($0) || (97...102).contains($0)
      }), let number = UInt64(hex, radix: 16)
    else { return nil }

    let red: UInt64
    let green: UInt64
    let blue: UInt64
    let alpha: UInt64

    switch hex.count {
    case 3:
      red = ((number >> 8) & 0xf) * 17
      green = ((number >> 4) & 0xf) * 17
      blue = (number & 0xf) * 17
      alpha = 255
    case 4:
      red = ((number >> 12) & 0xf) * 17
      green = ((number >> 8) & 0xf) * 17
      blue = ((number >> 4) & 0xf) * 17
      alpha = (number & 0xf) * 17
    case 6:
      red = (number >> 16) & 0xff
      green = (number >> 8) & 0xff
      blue = number & 0xff
      alpha = 255
    case 8:
      red = (number >> 24) & 0xff
      green = (number >> 16) & 0xff
      blue = (number >> 8) & 0xff
      alpha = number & 0xff
    default:
      return nil
    }

    self.init(
      .sRGB,
      red: Double(red) / 255,
      green: Double(green) / 255,
      blue: Double(blue) / 255,
      opacity: Double(alpha) / 255
    )
  }
}
