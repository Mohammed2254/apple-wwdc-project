# LifeQuest — README

## What is this?

**LifeQuest** is a cinematic interactive SwiftUI personality-quiz app.  
Every choice you make builds a *Trait Profile* revealing your personality archetype.

Two paths:
- 🛸 **Scholar** — Cyber-Zen — the Abroad Student journey  
- 🏕 **Scout** — Golden-Hour — the Wilderness Explorer journey

---

## Requirements

| Tool | Version |
|---|---|
| Xcode | 15.0+ |
| iOS Deployment Target | 17.0+ |
| Swift | 5.9+ |
| Swift Charts | Included in iOS 16+ SDK (no extra package needed) |

---

## Project Structure

```
LifeQuest/
 ├─ AppTheme.swift          Design tokens: gradients, colors, glass modifier
 ├─ Models.swift            Codable structs: LifePath, Scenario, Impact, etc.
 ├─ content.json            All scenarios and options (Bundle resource)
 ├─ GameEngine.swift        @MainActor ObservableObject — state machine
 ├─ PersonalityAnalyzer.swift  Trait tracking + delayed effects + finalReport
 ├─ Components.swift        Reusable views: buttons, HUD, overlay, result
 ├─ ContentView.swift       Top-level composition: Intro → Gameplay → Report
 └─ Assets.xcassets/        Images, colors (see Asset Setup below)
```

---

## How to Run in Xcode

1. Open `LifeQuest.xcodeproj` (or create a new SwiftUI project and add these files).
2. **Add files to target:**
   - Drag all `.swift` files into the Xcode navigator.
   - Add `content.json` to the target → ensure it appears in **Build Phases → Copy Bundle Resources**.
3. Select an iPhone simulator (e.g., iPhone 15 Pro).
4. Press **⌘R** to run.

---

## Asset Setup

### Assets.xcassets structure

Create the following image sets inside `Assets.xcassets`:

```
Assets.xcassets/
 ├─ AccentColor.colorset
 ├─ Mentor/
 │   ├─ mentor_scholar_avatar.imageset   (256×256 @3x)
 │   ├─ mentor_scholar_bust.imageset     (2048×2048 @1x)
 │   ├─ mentor_scout_avatar.imageset
 │   └─ mentor_scout_bust.imageset
 └─ Backgrounds/
     ├─ Scholar/
     │   ├─ scholar_bg_morning.imageset
     │   ├─ scholar_bg_afternoon.imageset
     │   └─ scholar_bg_night.imageset
     └─ Scout/
         ├─ scout_bg_morning.imageset
         ├─ scout_bg_afternoon.imageset
         └─ scout_bg_night.imageset
```

> The app gracefully falls back to SF Symbols if image assets are missing — so it runs without images immediately.

### Generating Images (Gemini Prompts)

**Scholar Mentor:**
```
Generate a cinematic mentor portrait for a mobile app (Arabic audience). Style: futuristic, calm, gender-neutral. Palette: Cyber-Zen (deep midnight, teal glow). Expression: gentle, inquisitive. Output: PNG 2048x2048 transparent. Also 256x256 avatar crop. Two variants: bust and half-body.
```

**Scout Mentor:**
```
Generate a cinematic mentor portrait: wise, warm, earthy textures, golden-hour rim light. Expression: kind & grounded. Output: PNG 2048x2048 transparent and 256x256 avatar. Two variants: bust & half-body.
```

---

## Gameplay Flow

```
App Start
   │
   ▼
IntroView ── tap path card ──► selectPath()
   │
   ▼
GameplayLayer
   │  currentScenario shown
   │  player taps option ──► makeChoice()
   │                              │
   │                              ▼
   │                        FeedbackOverlay
   │                              │
   │                        tap "متابعة" ──► next()
   │                              │
   │              ┌───────────────┘
   │              │ more scenarios?
   │              │  YES → next scenario
   │              │  NO  → isGameOver = true
   │
   ▼
FinalResultView ── "إعادة المحاولة" / "الرجوع" ──► restart()
```

---

## Personality Rules

| Condition | Title |
|---|---|
| caution ≥ 3 AND curiosity ≥ 2 | The Strategic Explorer |
| impulsivity ≥ 3 | The Bold Sprinter |
| empathy ≥ 3 | The Compassionate Leader |
| default | Balanced Seeker |

---

## Acceptance Checklist

- [ ] Compiles with zero errors (`⌘B`)
- [ ] Intro title fades in (1.2s), path cards slide up
- [ ] Choosing a path loads the correct scenario set with HUD + mentor banner
- [ ] Tapping a choice updates resilience/skill and shows feedback overlay
- [ ] Tapping "متابعة" advances to next scenario or shows Final Report
- [ ] Final Report shows personality title + message + chart
- [ ] Delayed hidden effects apply after the configured step count
- [ ] App supports Dark Mode and Dynamic Type
- [ ] All interactive elements have VoiceOver accessibility labels
- [ ] No network calls at runtime
- [ ] `content.json` is included in Copy Bundle Resources

---

## Risks & Mitigations

| Risk | Mitigation |
|---|---|
| `content.json` missing from bundle | `assertionFailure` + clear log message; add to Copy Bundle Resources |
| JSON schema mismatch | `Codable` strict keys; unit-test decode manually |
| Missing image assets | `AvatarView` falls back to SF Symbol automatically |
| Main-thread jank | JSON decoded once at init; no heavy processing in view body |

---

## License

MIT — feel free to adapt for educational or portfolio use.
