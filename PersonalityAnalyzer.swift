// PersonalityAnalyzer.swift
// Folder: LifeQuest/Sources/
// Tracks personality traits; supports immediate and delayed hidden effects.
// Fully deterministic finalReport() — no randomness, no networking.

import Foundation

// MARK: - DelayedEffect (private)

private struct DelayedEffect {
    /// Aggregated trait deltas: ["caution": 1, "impulsivity": -1]
    let effects: [String: Int]
    /// The step index at which these effects become active (inclusive).
    let applyAtStep: Int
}

// MARK: - PersonalityAnalyzer

final class PersonalityAnalyzer {

    // ── Trait scores ───────────────────────────────────────────────────────

    private(set) var traits: [String: Int] = [
        "caution":     0,
        "curiosity":   0,
        "empathy":     0,
        "impulsivity": 0
    ]

    // ── Internal state ─────────────────────────────────────────────────────

    private(set) var currentStep: Int = 0
    private var delayed: [DelayedEffect] = []

    // MARK: - Public API

    /// Apply hidden effects that should take place immediately.
    /// Call inside GameEngine.makeChoice() when delayImpact == 0.
    func recordImmediate(hidden: [HiddenEffect]) {
        for h in hidden { apply(key: h.key, delta: h.delta) }
    }

    /// Schedule hidden effects to fire after `afterSteps` future steps.
    /// Call inside GameEngine.makeChoice() when scenario.delayImpact > 0.
    func addDelayed(hidden: [HiddenEffect], afterSteps: Int) {
        guard afterSteps > 0, !hidden.isEmpty else { return }
        var map: [String: Int] = [:]
        for h in hidden { map[h.key, default: 0] += h.delta }
        delayed.append(DelayedEffect(effects: map, applyAtStep: currentStep + afterSteps))
    }

    /// Increment step counter and apply any matured delayed effects.
    /// Call inside GameEngine.next() before moving to the next scenario.
    func advanceStep() {
        currentStep += 1
        for (idx, item) in delayed.enumerated().reversed() {
            if item.applyAtStep <= currentStep {
                for (key, delta) in item.effects { apply(key: key, delta: delta) }
                delayed.remove(at: idx)
            }
        }
    }

    /// Reset all state for a new game session.
    func reset() {
        traits = ["caution": 0, "curiosity": 0, "empathy": 0, "impulsivity": 0]
        delayed.removeAll()
        currentStep = 0
    }

    // MARK: - Final Report

    /// Deterministic personality result. Rules evaluated top-to-bottom; first match wins.
    ///
    ///  1. caution ≥ 3 AND curiosity ≥ 2  → "The Strategic Explorer"
    ///  2. impulsivity ≥ 3               → "The Bold Sprinter"
    ///  3. empathy ≥ 3                   → "The Compassionate Leader"
    ///  4. default                        → "Balanced Seeker"
    func finalReport(resilience: Double, skill: Double) -> PersonalityReport {
        let caution     = traits["caution"]     ?? 0
        let curiosity   = traits["curiosity"]   ?? 0
        let impulsivity = traits["impulsivity"] ?? 0
        let empathy     = traits["empathy"]     ?? 0

        let title: String
        let message: String

        if caution >= 3 && curiosity >= 2 {
            title   = "The Strategic Explorer"
            message = "توازن رائع بين الحذر وحب الاستكشاف. ضع خططاً واضحة قبل كل مغامرة وستُبهر من حولك بنتائجك."
        } else if impulsivity >= 3 {
            title   = "The Bold Sprinter"
            message = "طاقتك ومبادرتك ميزة كبيرة. تمرّن على التوقف لحظة قبل كل قرار كبير — الثانية الواحدة تُغيّر المآل."
        } else if empathy >= 3 {
            title   = "The Compassionate Leader"
            message = "حساسيتك تجاه الآخرين قوة نادرة. استثمرها في بناء الفِرَق، وتذكّر أن العناية بنفسك أيضاً جزء من القيادة."
        } else {
            title   = "Balanced Seeker"
            message = "نهجك المتوازن أساس متين. ابنِ عادة يومية صغيرة في مجال واحد — الاتساق على المدى البعيد يتفوق على أي موهبة."
        }

        return PersonalityReport(
            title:      title,
            message:    message,
            traits:     traits,
            resilience: resilience,
            skill:      skill
        )
    }

    // MARK: - Private

    private func apply(key: String, delta: Int) {
        traits[key, default: 0] += delta
    }
}
