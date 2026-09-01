// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import SwiftUI



public enum Asset {
  public enum Colors {
    public static let accentColor = ColorAsset(name: "AccentColor")
    public static let backgroundPrimary = ColorAsset(name: "BackgroundPrimary")
    public static let surfacePrimary = ColorAsset(name: "SurfacePrimary")
    public static let textPrimary = ColorAsset(name: "TextPrimary")
  }
  public enum Images {
  }
}

public struct ColorAsset: Sendable {
  fileprivate let name: String

  @MainActor
  public var swiftUIColor: SwiftUI.Color {
    SwiftUI.Color(name)
  }
}
