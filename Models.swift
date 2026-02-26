// Models.swift
// Folder: LifeQuest/Models/
// iOS 17, Xcode 15 — no network, fully Codable, no force unwraps

import SwiftUI

// MARK: - LifePath

enum LifePath: String, Codable, CaseIterable, Identifiable, Hashable {
    case scholar
    case scout

    var id: String { rawValue }

    var title: String {
        switch self {
        case .scholar: return "مسار المستقبل"
        case .scout:   return "نداء البرية"
        }
    }

    var subtitle: String {
        switch self {
        case .scholar: return "المبتعث — Scholar"
        case .scout:   return "المغامر — Scout"
        }
    }

    var description: String {
        switch self {
        case .scholar: return "رحلة المبتعث نحو المعرفة والتكنولوجيا"
        case .scout:   return "مغامرة الاستكشاف والطبيعة والصمود"
        }
    }

    var icon: String {
        switch self {
        case .scholar: return "atom"
        case .scout:   return "mountain.2.fill"
        }
    }

    var accent: Color {
        switch self {
        case .scholar: return AppTheme.cyberAccent
        case .scout:   return AppTheme.scoutAccent
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .scholar: return AppTheme.cyberZen
        case .scout:   return AppTheme.goldenHour
        }
    }

    var mentorName: String {
        switch self {
        case .scholar: return "AI Guide"
        case .scout:   return "The Elder"
        }
    }

    /// Asset name in Assets.xcassets/Mentor/
    var mentorAvatarAsset: String {
        switch self {
        case .scholar: return "mentor_scholar_avatar"
        case .scout:   return "mentor_scout_avatar"
        }
    }
}

// MARK: - HiddenEffect

/// A single personality trait adjustment encoded in an option's hidden array.
/// key must be one of: "caution", "curiosity", "empathy", "impulsivity"
struct HiddenEffect: Codable {
    let key: String
    let delta: Int
}

// MARK: - Impact

struct Impact: Codable {
    let resilience: Int
    let skill: Int
    let hidden: [HiddenEffect]?
}

// MARK: - ScenarioOption

struct ScenarioOption: Codable {
    let id: String?
    let label: String
    let feedback: String
    let impact: Impact
    let contextTags: [String]?

    /// Stable identifier for diffing (falls back to label if id is nil)
    var stableId: String { id ?? label }
}

// MARK: - Scenario

struct Scenario: Codable, Identifiable {
    let id: String
    let text: String
    let icon: String
    let mentorAdvice: String
    let options: [ScenarioOption]
    let delayImpact: Int?
    let tags: [String]?

    var hasDelayedHidden: Bool { (delayImpact ?? 0) > 0 }
}

// MARK: - ContentDocument (root JSON object)

struct ContentDocument: Codable {
    let paths: [String: [Scenario]]

    func scenarios(for path: LifePath) -> [Scenario] {
        paths[path.rawValue] ?? []
    }
}

// MARK: - FeedbackInfo (transient UI, not decoded)

struct FeedbackInfo {
    let text: String
    let isPositive: Bool
}

// MARK: - PersonalityReport (generated, not decoded)

struct PersonalityReport {
    let title: String
    let message: String
    let traits: [String: Int]
    let resilience: Double
    let skill: Double
}
