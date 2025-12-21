# UI/UX Refactor Plan & Implementation Roadmap

This document outlines the planned improvements for the TapMine UI/UX, focusing on Neumorphic refinement, light source consistency, and UX friction reduction.

## 1. Neumorphic Refinement (Shadows & Depth)

### A. Shadow Softness Adjustment
*   **Target:** `lib/ui/theme/app_theme.dart`
*   **Change:** Adjust alpha values for `neumorphicDark` and `neumorphicLight`.
*   **Rationale:** Reduce "muddy" edges and increase visual "pop" on high-end displays.
```dart
static Color get neumorphicDark => Colors.black.withValues(alpha: 0.35);
static Color get neumorphicLight => Colors.white.withValues(alpha: 0.12);
```

### B. Unified Light Source Offset
*   **Target:** `NeumorphicDecoration` in `lib/ui/theme/app_theme.dart`
*   **Change:** Standardize `boxShadow` offsets to a consistent diagonal (Top-Left) to match `TapButton`.
*   **Offset:** `const Offset(5, 5)` for dark, `const Offset(-5, -5)` for light.

### C. Press State Logic
*   **Target:** `NeumorphicIconButton` in `lib/ui/widgets/neumorphic_widgets.dart`
*   **Change:** Use `concave` decoration instead of `flat(isPressed: true)` when tapped.
*   **Rationale:** Simulates physical displacement for better tactile feel.

## 2. UX Friction & Guidance

### A. Mission Selector Visual Cues
*   **Target:** `lib/ui/screens/home_screen.dart`
*   **Change:** 
    *   If no mission is active, add a pulse animation to the "Select Mission" area.
    *   Add a subtle "!" or "REQUIRED" badge to the `TapButton` when disabled due to missing mission.
*   **Rationale:** Stop relying on Snackbar warnings; provide proactive visual guidance.

### B. Cooldown Monetization Polish
*   **Target:** `lib/ui/screens/home_screen.dart` / `NeumorphicButton`
*   **Change:** Implement a "Premium Shimmer" on the "Watch Ad" button during cooldown.
*   **Rationale:** High-value actions should look different from standard secondary buttons.

## 3. Tactile Feedback (Haptics)

### A. Energy Depletion Feedback
*   **Target:** `lib/ui/widgets/tap_button.dart`
*   **Change:** Trigger `HapticFeedback.mediumImpact()` when energy reaches 0.
*   **Rationale:** Differentiate "working" taps from "exhausted" taps through physical vibration.

## 4. Cleaning & Maintenance

### A. Background Simplification
*   **Target:** `lib/ui/widgets/neumorphic_widgets.dart` and `lib/ui/screens/home_screen.dart`
*   **Action:** Remove `CyberBackground` and the animated grid painter.
*   **Rationale:** Shift focus entirely to the Neumorphic cards and containers; reduce battery drain from continuous background painting.
