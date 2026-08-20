# Habit Tracker Design Guide

## Design Philosophy

The Habit Tracker uses a modern, clean design language optimized for light mode only. The design prioritizes clarity, accessibility, and an intuitive user experience.

## Design System

### Color Palette (Light Mode Only)

**Backgrounds:**
- Background: `#FAFAFA` (Light gray)
- Surface Primary: `#FFFFFF` (White)
- Surface Secondary: `#F7F7F7` (Very light gray)

**Text:**
- Primary: `#212121` (Dark gray)
- Secondary: `#858789` (Medium gray)
- Tertiary: `#B8B9BB` (Light gray)

**Semantic:**
- Success: `#36B650` (Green)
- Warning: `#FFA500` (Orange)
- Error: `#ED4651` (Red)
- Info: `#2196F3` (Blue)

**Status:**
- Active: Success (Green)
- Paused: Warning (Orange)
- Archived: Tertiary (Gray)

**Streaks:**
- 3-Day: Fire Orange
- 7-Day: Star Gold
- 30-Day: Trophy Gold

### Typography

| Size | Weight | Usage |
|------|--------|-------|
| 32pt | Bold | Title 1 (Page headers) |
| 28pt | Bold | Title 2 (Section headers) |
| 22pt | Semibold | Title 3 (Subsections) |
| 18pt | Semibold | Headline (Card titles) |
| 16pt | Semibold | Subheadline (Labels) |
| 16pt | Regular | Body (Main content) |
| 14pt | Regular | Body Small (Secondary content) |
| 12pt | Regular | Caption (Tertiary content) |
| 12pt | Semibold | Caption Bold (Accents) |

### Spacing

| Size | Pixels | Usage |
|------|--------|-------|
| XS | 4 | Tiny gaps, icon spacing |
| SM | 8 | Component padding, margins |
| MD | 12 | Internal component spacing |
| LG | 16 | Card padding, sections |
| XL | 24 | Major sections |
| XXL | 32 | Page padding |

### Corner Radius

| Size | Pixels | Usage |
|------|--------|-------|
| SM | 6 | Small pills, badges |
| MD | 8 | Medium buttons, controls |
| LG | 12 | Cards, containers |
| XL | 16 | Surfaces, large containers |

### Shadows

| Style | Blur | Offset | Opacity | Usage |
|-------|------|--------|---------|-------|
| SM | 2 | 1 | 5% | Subtle elevation |
| MD | 4 | 2 | 8% | Card elevation |
| LG | 8 | 4 | 10% | Modal elevation |

### Animation

| Type | Duration | Usage |
|------|----------|-------|
| Quick | 0.2s | Button interactions |
| Standard | 0.3s | Page transitions |
| Slow | 0.5s | Notification slides |

## Components

### Habit Card

**Layout:**
- Header: Name + Status badge + Today indicator
- Divider line
- Stats row: Current streak, Best streak, Total check-ins
- Action button (check-in or checked indicator)

**States:**
- Active: Full interactivity
- Completed today: Check-in button disabled, green background
- Not completed: Check-in button enabled, blue background
- Paused/Archived: No action button

**Accessibility:**
- Accessible label: "Habit: [name]"
- Accessible hint: "Streak: [days] days. [Today status]"

### Search Bar

**Features:**
- Search icon on left
- Clear button on right (appears when text entered)
- Light background
- Rounded corners (MD radius)

### Filter Pills

**Types:**
- Status filters: Active, Paused, Archived
- Completion filter: Completed Today
- Clear filters button

**States:**
- Selected: Blue background, white text
- Unselected: Light blue background, blue text

### Summary Stats

**Cards show:**
- Total habits count
- Today completed count
- Maximum current streak

## Layout

### Desktop (iPad and larger)

- Full-width responsive
- Generous padding (XXL)
- Wide habit cards with complete information
- Sidebar for filters (optional)

### Mobile (iPhone)

- Compact padding (LG)
- Full-width cards
- Stacked filters
- Single column layout

## Dark Mode

**Not supported in this version.** All UIs are light mode only for consistency and simplicity.

## Accessibility

### Color Contrast

All text meets WCAG AA standards:
- Primary text on white: 10.8:1
- Secondary text on white: 4.0:1
- Semantic colors: 4.5:1 minimum

### Text Sizing

- Minimum 12pt for readable content
- Relative sizing for user font preferences
- Generous line spacing (1.5x)

### Interactions

- Touch targets: Minimum 44pt × 44pt
- Clear hover/focus states
- Accessible labels for all buttons
- Descriptive accessibility hints

### Semantic Structure

- Proper heading hierarchy
- Descriptive alt text for icons
- Form labels and hints
- Error message clarity

## Best Practices

### Visual Hierarchy

1. **Primary actions**: Blue, prominent buttons
2. **Secondary actions**: Light backgrounds
3. **Tertiary actions**: Subtle text buttons
4. **Status information**: Color-coded badges

### Spacing

- Consistent internal padding (LG)
- Consistent external margins (MD)
- Breathing room around important elements
- Grouped related items with smaller spacing

### Icons

- Use SF Symbols exclusively
- Consistent sizing (12pt, 16pt, 24pt)
- Color-coded by type (status, streak, action)
- Never use purely decorative icons

### Animation

- Use standard timing (0.3s) for most transitions
- Quicken for feedback (0.2s) on button taps
- Slow for attention-grabbing (0.5s) on notifications
- Always provide option to reduce motion

## Implementation

Use the `DesignTokens` enum for all design values:

```swift
import SwiftUI

// Colors
Text("Hello")
  .foregroundColor(DesignTokens.Colors.textPrimary)

// Typography
Text("Title")
  .font(DesignTokens.Typography.headline)

// Spacing
VStack(spacing: DesignTokens.Spacing.md) { ... }

// Styling
VStack { ... }
  .cardStyle()
  .surfaceStyle()
```

This ensures consistency across the entire app.
