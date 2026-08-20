//
//  DesignTokens.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import SwiftUI

enum DesignTokens {
  // MARK: - Spacing

  enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
  }

  // MARK: - Corner Radius

  enum CornerRadius {
    static let sm: CGFloat = 6
    static let md: CGFloat = 8
    static let lg: CGFloat = 12
    static let xl: CGFloat = 16
  }

  // MARK: - Typography

  enum Typography {
    static let title1 = Font.system(size: 32, weight: .bold, design: .default)
    static let title2 = Font.system(size: 28, weight: .bold, design: .default)
    static let title3 = Font.system(size: 22, weight: .semibold, design: .default)
    static let headline = Font.system(size: 18, weight: .semibold, design: .default)
    static let subheadline = Font.system(size: 16, weight: .semibold, design: .default)
    static let body = Font.system(size: 16, weight: .regular, design: .default)
    static let bodySmall = Font.system(size: 14, weight: .regular, design: .default)
    static let caption = Font.system(size: 12, weight: .regular, design: .default)
    static let captionBold = Font.system(size: 12, weight: .semibold, design: .default)
  }

  // MARK: - Colors (Light Mode Only)

  enum Colors {
    static let background = Color(red: 0.98, green: 0.98, blue: 0.98)
    static let surfacePrimary = Color.white
    static let surfaceSecondary = Color(red: 0.97, green: 0.97, blue: 0.97)
    static let textPrimary = Color(red: 0.13, green: 0.13, blue: 0.13)
    static let textSecondary = Color(red: 0.52, green: 0.53, blue: 0.55)
    static let textTertiary = Color(red: 0.72, green: 0.73, blue: 0.75)
    static let divider = Color(red: 0.92, green: 0.92, blue: 0.92)

    // Semantic colors
    static let success = Color(red: 0.21, green: 0.71, blue: 0.43)
    static let warning = Color(red: 1.0, green: 0.65, blue: 0.0)
    static let error = Color(red: 0.93, green: 0.28, blue: 0.33)
    static let info = Color(red: 0.13, green: 0.59, blue: 1.0)

    // Status colors
    static let activeGreen = Color(red: 0.21, green: 0.71, blue: 0.43)
    static let pausedOrange = Color(red: 1.0, green: 0.65, blue: 0.0)
    static let archivedGray = Color(red: 0.72, green: 0.73, blue: 0.75)

    // Streak colors
    static let streakFire = Color(red: 1.0, green: 0.60, blue: 0.0)
    static let streakStar = Color(red: 1.0, green: 0.85, blue: 0.0)
    static let streakTrophy = Color(red: 0.89, green: 0.61, blue: 0.0)
  }

  // MARK: - Shadows

  enum Shadows {
    static let sm = Shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    static let md = Shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
    static let lg = Shadow(color: .black.opacity(0.10), radius: 8, x: 0, y: 4)
  }

  // MARK: - Animation

  enum Animation {
    static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
    static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
    static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
  }
}

// MARK: - Helper View Modifiers

extension View {
  func surfaceStyle() -> some View {
    self
      .background(DesignTokens.Colors.surfacePrimary)
      .cornerRadius(DesignTokens.CornerRadius.lg)
      .shadow(color: DesignTokens.Shadows.md.color, radius: DesignTokens.Shadows.md.radius)
  }

  func cardStyle() -> some View {
    self
      .background(DesignTokens.Colors.surfacePrimary)
      .cornerRadius(DesignTokens.CornerRadius.md)
      .shadow(color: DesignTokens.Shadows.sm.color, radius: DesignTokens.Shadows.sm.radius)
  }
}
