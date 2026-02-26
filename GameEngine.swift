// GameEngine.swift
// Folder: LifeQuest/Sources/
// @MainActor ObservableObject — single source of truth for the entire app state.
//
// Published property names (used verbatim in ContentView & Components):
//   selectedPath, scenarios, currentScenarioIndex, resilience, skill,
//   timeOfDay, showFeedback, lastFeedback, isGameOver
import Foundation
import SwiftUI
@MainActor
final class GameEngine: ObservableObject {
    // ── Published state ────────────────────────────────────────────────────
    @Published private(set) var selectedPath: LifePath?         = nil
    @Published private(set) var scenarios: [Scenario]           = []
    @Published private(set) var currentScenarioIndex: Int       = 0
    @Published private(set) var resilience: Double              = 50
    @Published private(set) var skill: Double                   = 50
    @Published private(set) var timeOfDay: Double               = 0.0
    @Published              var showFeedback: Bool              = false
    @Published private(set) var lastFeedback: FeedbackInfo?     = nil
    @Published private(set) var isGameOver: Bool                = false
    // ── Internal ───────────────────────────────────────────────────────────
    private let analyzer = PersonalityAnalyzer()
    private var contentDocument: ContentDocument?
    // MARK: - Init
    init() { loadContent() }
    // MARK: - Content Loading
    /// Safely decodes content.json from the main Bundle.
    /// Uses print instead of assertionFailure to prevent SwiftUI Previews from crashing
    /// if the JSON file hasn't been added to the target yet.
    private func loadContent() {
        // Try Bundle.main first (standard app run)
        // Try Bundle(for: GameEngine.self) as a fallback (sometimes helps in Previews)
        let bundle = Bundle.main
        guard let url = bundle.url(forResource: "content", withExtension: "json") else {
            print("⚠️ [LifeQuest] content.json not found in bundle. Preview might be empty until the file is added to Copy Bundle Resources.")
            return
        }
        do {
            let data = try Data(contentsOf: url)
            contentDocument = try JSONDecoder().decode(ContentDocument.self, from: data)
            print("✅ [LifeQuest] content.json loaded successfully.")
        } catch {
            print("🛑 [LifeQuest] content.json decode error: \(error)")
        }
    }
    // MARK: - Path Selection
    func selectPath(_ path: LifePath) {
        guard let doc = contentDocument else { return }
        scenarios            = doc.scenarios(for: path)
        currentScenarioIndex = 0
        resilience           = 50
        skill                = 50
        timeOfDay            = 0.0
        showFeedback         = false
        lastFeedback         = nil
        isGameOver           = false
        analyzer.reset()
        withAnimation(.spring(response: 0.9, dampingFraction: 0.78)) {
            selectedPath = path
        }
    }
    // MARK: - Computed Helpers
    var currentScenario: Scenario? {
        guard currentScenarioIndex < scenarios.count else { return nil }
        return scenarios[currentScenarioIndex]
    }
    var progressFraction: Double {
        guard !scenarios.isEmpty else { return 0 }
        return Double(currentScenarioIndex) / Double(scenarios.count)
    }
    // MARK: - Choice Handling
    func makeChoice(optionIndex: Int) {
        guard let scenario = currentScenario,
              optionIndex < scenario.options.count else { return }
        let option = scenario.options[optionIndex]
        let impact = option.impact
        // 1. Apply immediate visible impacts (bounded 0...100)
        withAnimation(.easeOut(duration: 0.4)) {
            resilience = clamped(resilience + Double(impact.resilience))
            skill      = clamped(skill      + Double(impact.skill))
        }
        // 2. Record hidden effects in analyzer
        let hiddenEffects = impact.hidden ?? []
        let delaySteps    = scenario.delayImpact ?? 0
        if delaySteps > 0 {
            analyzer.addDelayed(hidden: hiddenEffects, afterSteps: delaySteps)
        } else {
            analyzer.recordImmediate(hidden: hiddenEffects)
        }
        // 3. Advance time of day (+0.20 per choice, capped at 1.0)
        withAnimation(.easeInOut(duration: 0.8)) {
            timeOfDay = min(1.0, timeOfDay + 0.20)
        }
        // 4. Show feedback overlay
        let isPositive = impact.resilience >= 0 && impact.skill >= 0
        lastFeedback = FeedbackInfo(text: option.feedback, isPositive: isPositive)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showFeedback = true
        }
    }
    // MARK: - Progression
    /// Dismiss feedback and advance to the next scenario (or end game).
    func next() {
        analyzer.advanceStep()
        withAnimation(.easeInOut(duration: 0.35)) {
            showFeedback = false
        }
        let nextIndex = currentScenarioIndex + 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self = self else { return }
            if nextIndex < self.scenarios.count {
                withAnimation(.easeInOut(duration: 0.4)) {
                    self.currentScenarioIndex = nextIndex
                }
            } else {
                withAnimation(.spring(response: 0.9, dampingFraction: 0.8)) {
                    self.isGameOver = true
                }
            }
        }
    }
    // MARK: - Final Personality
    func finalPersonality() -> PersonalityReport {
        analyzer.finalReport(resilience: resilience, skill: skill)
    }
    // MARK: - Restart
    func restart() {
        withAnimation(.easeInOut(duration: 0.5)) {
            selectedPath = nil
            isGameOver   = false
            showFeedback = false
            lastFeedback = nil
        }
    }
    // MARK: - Private helpers
    private func clamped(_ value: Double) -> Double {
        min(100, max(0, value))
    }
}
