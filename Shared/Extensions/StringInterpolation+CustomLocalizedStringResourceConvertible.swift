import SwiftUI

extension LocalizedStringKey.StringInterpolation {
  public mutating func appendInterpolation(_ value: any CustomLocalizedStringResourceConvertible) {
    appendInterpolation(value.localizedStringResource)
  }
}
