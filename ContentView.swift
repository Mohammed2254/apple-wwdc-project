// ContentView.swift
// Folder: LifeQuest/Views/
// Root composition view. Drives app state via GameEngine @StateObject.
//
// View hierarchy:
//   ContentView
//    ├─ LivingBackground    animated gradient + fog circles
//    ├─ IntroView           (selectedPath == nil)
//    │   ├─ hero title + subtitle (fade-in 1.2s)
//    │   └─ PathCardView × 2 (spring slide-up 0.9s)
//    └─ GameplayLayer       (selectedPath != nil && !isGameOver)
//        ├─ HUDCapsule      (top glass pill)
//        ├─ MentorBannerView
//        ├─ ScenarioCardView
//        ├─ ChoiceButton × 2
//        └─ FeedbackOverlayView (conditional overlay)
//    └─ FinalResultView     (isGameOver == true)

import SwiftUI

// MARK: - ContentView (Root)

struct ContentView: View {
    @StateObject private var engine = GameEngine()

    var body: some View {
        ZStack {
            LivingBackground(path: engine.selectedPath, timeOfDay: engine.timeOfDay)
                .ignoresSafeArea()

            if let path = engine.selectedPath {
                if engine.isGameOver {
                    FinalResultView(
                        report:    engine.finalPersonality(),
                        path:      path,
                        onRestart: { engine.restart() },
                        onHome:    { engine.restart() }
                    )
                    .transition(.asymmetric(
                        insertion:  .opacity.combined(with: .scale(scale: 0.96)),
                        removal:    .opacity
                    ))
                } else {
                    GameplayLayer(engine: engine, path: path)
                        .transition(.asymmetric(
                            insertion:  .opacity.combined(with: .move(edge: .trailing)),
                            removal:    .opacity
                        ))
                }
            } else {
                IntroView(engine: engine)
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.9, dampingFraction: 0.78), value: engine.selectedPath)
        .animation(.easeInOut(duration: 0.5), value: engine.isGameOver)
        .preferredColorScheme(.dark)
        .environment(\.layoutDirection, .rightToLeft)
    }
}

// MARK: - LivingBackground

/// Animated full-screen background adapting to path and time-of-day.
struct LivingBackground: View {
    let path: LifePath?
    let timeOfDay: Double

    @State private var fogOffset1 = CGSize(width: -60, height: -40)
    @State private var fogOffset2 = CGSize(width:  80, height:  60)

    var body: some View {
        ZStack {
            if let path = path {
                path.gradient
            } else {
                AppTheme.introBackground
            }

            // Time-of-day darkening when in gameplay
            if path != nil {
                Color.black.opacity(timeOfDay * 0.55)
                    .animation(.easeInOut(duration: 0.8), value: timeOfDay)
            }

            // Animated fog — intro only
            if path == nil {
                fogLayer
            }
        }
        .animation(.easeInOut(duration: 1.2), value: path?.rawValue)
        .onAppear { startFogAnimation() }
    }

    private var fogLayer: some View {
        GeometryReader { geo in
            ZStack {
                FogCircle(
                    color:  AppTheme.fogTeal,
                    size:   geo.size.width * 0.75,
                    offset: fogOffset1
                )
                .position(x: geo.size.width * 0.2, y: geo.size.height * 0.3)

                FogCircle(
                    color:  AppTheme.fogAmber,
                    size:   geo.size.width * 0.65,
                    offset: fogOffset2
                )
                .position(x: geo.size.width * 0.8, y: geo.size.height * 0.7)
            }
        }
    }

    private func startFogAnimation() {
        withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
            fogOffset1 = CGSize(width:  30, height:  50)
            fogOffset2 = CGSize(width: -50, height: -30)
        }
    }
}

// MARK: - IntroView

/// Cinematic landing screen with animated title and spring path-card entrance.
struct IntroView: View {
    @ObservedObject var engine: GameEngine

    @State private var titleOpacity:    Double  = 0
    @State private var titleOffset:     CGFloat = 24
    @State private var subtitleOpacity: Double  = 0
    @State private var cardsOffset:     CGFloat = 60
    @State private var cardsOpacity:    Double  = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Hero title
            VStack(spacing: 8) {
                Text("LifeQuest")
                    .font(AppTheme.displayFont(size: 56))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, AppTheme.cyberAccent],
                            startPoint: .topLeading,
                            endPoint:   .bottomTrailing
                        )
                    )
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityLabel("LifeQuest — تطبيق رحلة الحياة")

                Text("كل اختيار.. يصنع واقعك")
                    .font(AppTheme.headlineFont(size: 18))
                    .foregroundColor(AppTheme.mutedLabel)
                    .opacity(subtitleOpacity)
            }
            .opacity(titleOpacity)
            .offset(y: titleOffset)

            Spacer().frame(height: 56)

            // Path cards
            VStack(spacing: 16) {
                ForEach(LifePath.allCases) { path in
                    PathCardView(path: path) {
                        engine.selectPath(path)
                    }
                }
            }
            .padding(.horizontal, AppTheme.screenPad)
            .offset(y: cardsOffset)
            .opacity(cardsOpacity)

            Spacer()
        }
        .onAppear { runEntrance() }
    }

    private func runEntrance() {
        withAnimation(.easeOut(duration: 1.2)) {
            titleOpacity = 1
            titleOffset  = 0
        }
        withAnimation(.easeOut(duration: 1.0).delay(0.5)) {
            subtitleOpacity = 1
        }
        withAnimation(.spring(response: 0.9, dampingFraction: 0.78).delay(0.7)) {
            cardsOffset  = 0
            cardsOpacity = 1
        }
    }
}

// MARK: - PathCardView

struct PathCardView: View {
    let path:   LifePath
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(path.accent.opacity(0.18))
                        .frame(width: 56, height: 56)
                    Image(systemName: path.icon)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(path.accent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(path.title)
                        .font(AppTheme.headlineFont(size: 18))
                        .foregroundColor(.white)
                    Text(path.description)
                        .font(AppTheme.bodyFont(size: 13))
                        .foregroundColor(AppTheme.mutedLabel)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.left") // RTL: left = forward arrow
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(path.accent.opacity(0.7))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                    .fill(AppTheme.cardSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                            .strokeBorder(path.accent.opacity(0.35), lineWidth: 1)
                    )
            )
            .scaleEffect(isHovered ? 1.04 : 1.0)
            .shadow(color: path.accent.opacity(isHovered ? 0.3 : 0.0), radius: 20, y: 6)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.spring(response: 0.25)) { isHovered = true  } }
                .onEnded   { _ in withAnimation(.spring(response: 0.25)) { isHovered = false } }
        )
        .accessibilityLabel("\(path.title): \(path.description)")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - GameplayLayer

/// Main gameplay screen: HUD, mentor, scenario card, choice buttons, feedback overlay.
struct GameplayLayer: View {
    @ObservedObject var engine: GameEngine
    let path: LifePath

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // HUD
                HUDCapsule(engine: engine, path: path)
                    .padding(.horizontal, AppTheme.screenPad)
                    .padding(.top, 8)

                Spacer().frame(height: 12)

                // Mentor banner
                if let scenario = engine.currentScenario {
                    MentorBannerView(
                        mentorName: path.mentorName,
                        advice:     scenario.mentorAdvice,
                        imageName:  path.mentorAvatarAsset,
                        accent:     path.accent
                    )
                    .padding(.horizontal, AppTheme.screenPad)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                Spacer()

                // Scenario card
                if let scenario = engine.currentScenario {
                    ScenarioCardView(scenario: scenario, accent: path.accent)
                        .padding(.horizontal, AppTheme.screenPad)
                        .transition(.scale(scale: 0.95).combined(with: .opacity))
                        .id(scenario.id)
                }

                Spacer()

                // Choice buttons
                if let scenario = engine.currentScenario {
                    VStack(spacing: 12) {
                        ForEach(Array(scenario.options.enumerated()), id: \.offset) { idx, option in
                            ChoiceButton(label: option.label, accent: path.accent) {
                                engine.makeChoice(optionIndex: idx)
                            }
                        }
                    }
                    .padding(.horizontal, AppTheme.screenPad)
                    .padding(.bottom, 44)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: engine.currentScenarioIndex)

            // Feedback overlay
            if engine.showFeedback, let feedback = engine.lastFeedback {
                FeedbackOverlayView(
                    feedback:   feedback,
                    accent:     path.accent,
                    onContinue: { engine.next() }
                )
                .animation(.easeInOut(duration: 0.3), value: engine.showFeedback)
            }
        }
    }
}

// MARK: - HUDCapsule

/// Top glass pill: avatar + animated stat bars + scenario progress counter.
struct HUDCapsule: View {
    @ObservedObject var engine: GameEngine
    let path: LifePath

    var body: some View {
        HStack(spacing: 14) {
            AvatarView(imageName: path.mentorAvatarAsset, size: 40, accent: path.accent)

            HUDBarView(
                resilience: engine.resilience,
                skill:      engine.skill,
                accent:     path.accent
            )

            Spacer()

            // Scenario counter
            Text("\(engine.currentScenarioIndex + 1)/\(engine.scenarios.count)")
                .font(AppTheme.captionFont(size: 12))
                .foregroundColor(path.accent)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(path.accent.opacity(0.15)))
                .accessibilityLabel("السيناريو \(engine.currentScenarioIndex + 1) من \(engine.scenarios.count)")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .glassCard()
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - ScenarioCardView

/// Floating glass card displaying the current scenario icon and text.
struct ScenarioCardView: View {
    let scenario: Scenario
    let accent: Color

    @State private var appeared = false

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.15))
                    .frame(width: 60, height: 60)
                Image(systemName: scenario.icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(accent)
            }

            Text(scenario.text)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white.opacity(0.92))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(4)
        }
        .padding(24)
        .glassCard()
        .scaleEffect(appeared ? 1.0 : 0.94)
        .opacity(appeared ?   1.0 :  0.0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                appeared = true
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("السيناريو: \(scenario.text)")
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
