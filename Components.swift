// Components.swift
// Folder: LifeQuest/Views/
// All reusable UI primitives. Each view carries full accessibility labels.
//
// Requires: AppTheme.swift, Models.swift, GameEngine.swift
// import UIKit is required for UINotificationFeedbackGenerator and UIImage.

import SwiftUI
import Charts
import UIKit

// MARK: - ScaleButtonStyle

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - ChoiceButton

/// Wide pill action button for scenario option choices.
struct ChoiceButton: View {
    let label:  String
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(AppTheme.bodyFont(size: 16))
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.buttonRadius, style: .continuous)
                        .fill(accent.opacity(0.85))
                        .shadow(color: accent.opacity(0.4), radius: 8, y: 4)
                )
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel(label)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - HUDBarView

/// Two labelled animated progress bars for resilience and skill.
struct HUDBarView: View {
    let resilience: Double
    let skill: Double
    let accent: Color

    var body: some View {
        HStack(spacing: 16) {
            statBar(label: "🛡 Resilience", value: resilience, color: accent)
            statBar(label: "⚡ Skill",      value: skill,      color: accent.opacity(0.75))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Resilience \(Int(resilience)) بالمئة، Skill \(Int(skill)) بالمئة")
    }

    private func statBar(label: String, value: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(AppTheme.captionFont(size: 11))
                .foregroundColor(AppTheme.mutedLabel)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.1))
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * value / 100)
                        .animation(.spring(response: 0.6, dampingFraction: 0.75), value: value)
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - AvatarView

/// Circular mentor portrait with accent ring. Falls back to SF Symbol if asset missing.
struct AvatarView: View {
    let imageName: String
    let size: CGFloat
    let accent: Color

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [accent, accent.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint:   .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: size + 4, height: size + 4)

            Group {
                if UIImage(named: imageName) != nil {
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: size * 0.45))
                        .foregroundColor(accent)
                }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
        }
        .accessibilityHidden(true)
    }
}

// MARK: - MentorBannerView

/// Glass pill card — mentor avatar + name + advice text.
struct MentorBannerView: View {
    let mentorName: String
    let advice: String
    let imageName: String
    let accent: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AvatarView(imageName: imageName, size: 44, accent: accent)

            VStack(alignment: .leading, spacing: 3) {
                Text(mentorName)
                    .font(AppTheme.captionFont(size: 12))
                    .foregroundColor(accent)

                Text(advice)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.88))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .glassCard()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(mentorName) ينصح: \(advice)")
    }
}

// MARK: - FeedbackOverlayView

/// Full-screen dark scrim + spring-scaled dialog shown after every choice.
struct FeedbackOverlayView: View {
    let feedback: FeedbackInfo
    let accent: Color
    let onContinue: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            // Scrim — absorbs taps beneath the dialog
            Color.black.opacity(0.62)
                .ignoresSafeArea()
                .onTapGesture {}

            VStack(spacing: 20) {
                // Icon
                ZStack {
                    Circle()
                        .fill((feedback.isPositive ? Color.green : Color.orange).opacity(0.18))
                        .frame(width: 72, height: 72)
                    Image(systemName: feedback.isPositive ? "checkmark.circle.fill" : "lightbulb.fill")
                        .font(.system(size: 36))
                        .foregroundColor(feedback.isPositive ? .green : .orange)
                }
                .shadow(
                    color: (feedback.isPositive ? Color.green : Color.orange).opacity(0.45),
                    radius: 14
                )

                Text(feedback.isPositive ? "اختيار موفق 🌟" : "درس مهم 💡")
                    .font(AppTheme.headlineFont(size: 18))
                    .foregroundColor(.white)

                Text(feedback.text)
                    .font(AppTheme.bodyFont(size: 15))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Button(action: {
                    let gen = UINotificationFeedbackGenerator()
                    gen.notificationOccurred(feedback.isPositive ? .success : .warning)
                    onContinue()
                }) {
                    Text("متابعة →")
                        .font(AppTheme.bodyFont(size: 16))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.buttonRadius, style: .continuous)
                                .fill(accent)
                        )
                }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel("متابعة إلى السيناريو التالي")
                .accessibilityAddTraits(.isButton)
            }
            .padding(28)
            .glassCard()
            .padding(.horizontal, 28)
            .scaleEffect(appeared ? 1.0 : 0.8)
            .opacity(appeared ? 1.0 : 0.0)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    appeared = true
                }
            }
        }
        .transition(.opacity)
        .zIndex(99)
    }
}

// MARK: - FinalResultView

/// Personality report screen: badge, title, message, stat rows, trait chart, actions.
struct FinalResultView: View {
    let report: PersonalityReport
    let path: LifePath
    let onRestart: () -> Void
    let onHome: () -> Void

    @State private var chartAppeared = false
    @State private var badgeScale: CGFloat   = 0.5
    @State private var badgeOpacity: Double  = 0.0

    var body: some View {
        ZStack {
            path.gradient.ignoresSafeArea()
            Color.black.opacity(0.45).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    Spacer(minLength: 40)
                    badgeSection
                    titleSection
                    statsCard
                    traitsChart
                    actionButtons
                    Spacer(minLength: 60)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.65).delay(0.2)) {
                badgeScale    = 1.0
                badgeOpacity  = 1.0
                chartAppeared = true
            }
        }
    }

    // ── Badge ──────────────────────────────────────────────────────────────

    private var badgeSection: some View {
        ZStack {
            Circle()
                .fill(path.accent.opacity(0.2))
                .frame(width: 100, height: 100)
                .blur(radius: 16)
            Image(systemName: "star.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(path.accent, Color.white.opacity(0.25))
                .shadow(color: path.accent.opacity(0.7), radius: 20)
        }
        .scaleEffect(badgeScale)
        .opacity(badgeOpacity)
        .accessibilityHidden(true)
    }

    // ── Title + message ────────────────────────────────────────────────────

    private var titleSection: some View {
        VStack(spacing: 12) {
            Text(report.title)
                .font(AppTheme.displayFont(size: 30))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
                .accessibilityLabel("لقبك: \(report.title)")

            Text(report.message)
                .font(AppTheme.bodyFont(size: 16))
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .accessibilityLabel(report.message)
        }
        .padding(.horizontal, AppTheme.screenPad)
    }

    // ── Resilience / Skill rows ────────────────────────────────────────────

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("نتائجك")
                .font(AppTheme.headlineFont(size: 16))
                .foregroundColor(path.accent)

            VStack(spacing: 10) {
                statRow(name: "Resilience", value: report.resilience, color: path.accent)
                statRow(name: "Skill",      value: report.skill,      color: path.accent.opacity(0.7))
            }
        }
        .padding(20)
        .glassCard()
        .padding(.horizontal, AppTheme.screenPad)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Resilience \(Int(report.resilience))، Skill \(Int(report.skill))")
    }

    private func statRow(name: String, value: Double, color: Color) -> some View {
        HStack {
            Text(name)
                .font(AppTheme.bodyFont(size: 14))
                .foregroundColor(.white.opacity(0.8))
            Spacer()
            Text("\(Int(value))%")
                .font(AppTheme.captionFont(size: 13))
                .foregroundColor(color)
        }
    }

    // ── Traits bar chart ───────────────────────────────────────────────────

    private var traitData: [(trait: String, value: Int)] {
        let labels = [
            "caution":     "حذر",
            "curiosity":   "فضول",
            "empathy":     "تعاطف",
            "impulsivity": "تلقائية"
        ]
        return report.traits
            .sorted { $0.key < $1.key }
            .map { (labels[$0.key] ?? $0.key, max(0, $0.value)) }
    }

    private var traitsChart: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("ملف الشخصية")
                .font(AppTheme.headlineFont(size: 16))
                .foregroundColor(path.accent)

            Chart(traitData, id: \.trait) { item in
                BarMark(
                    x: .value("القيمة", chartAppeared ? item.value : 0),
                    y: .value("السمة",  item.trait)
                )
                .foregroundStyle(path.gradient)
                .cornerRadius(6)
                .annotation(position: .trailing) {
                    Text("\(item.value)")
                        .font(AppTheme.captionFont(size: 12))
                        .foregroundColor(.white.opacity(0.75))
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.85))
                }
            }
            .frame(height: 160)
            .animation(.spring(response: 0.8, dampingFraction: 0.75).delay(0.3), value: chartAppeared)
        }
        .padding(20)
        .glassCard()
        .padding(.horizontal, AppTheme.screenPad)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("مخطط سمات الشخصية: حذر \(report.traits["caution"] ?? 0)، فضول \(report.traits["curiosity"] ?? 0)، تعاطف \(report.traits["empathy"] ?? 0)، تلقائية \(report.traits["impulsivity"] ?? 0)")
    }

    // ── Action buttons ─────────────────────────────────────────────────────

    private var actionButtons: some View {
        VStack(spacing: 12) {
            ChoiceButton(label: "🔄  إعادة المحاولة", accent: path.accent, action: onRestart)

            Button(action: onHome) {
                Text("الصفحة الرئيسية")
                    .font(AppTheme.bodyFont(size: 15))
                    .foregroundColor(.white.opacity(0.75))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.buttonRadius, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                    )
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityLabel("العودة إلى الصفحة الرئيسية")
            .accessibilityAddTraits(.isButton)
        }
        .padding(.horizontal, AppTheme.screenPad)
    }
}
