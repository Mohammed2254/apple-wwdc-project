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
        // Find the bundle containing content.json (handles both App and Preview environments)
        let bundle = Bundle.main.url(forResource: "content", withExtension: "json") != nil ? Bundle.main : Bundle(for: GameEngine.self)
        
        if let url = bundle.url(forResource: "content", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                contentDocument = try JSONDecoder().decode(ContentDocument.self, from: data)
                print("✅ [LifeQuest] content.json loaded from bundle.")
                return
            } catch {
                print("🛑 [LifeQuest] content.json decode error: \(error)")
            }
        }
        
        // --- PLAYGROUND FALLBACK ---
        print("⚠️ [LifeQuest] File not found in Bundle. Using embedded JSON fallback for App Playgrounds!")
        let data = Data(fallbackJSON.utf8)
        do {
            contentDocument = try JSONDecoder().decode(ContentDocument.self, from: data)
            print("✅ [LifeQuest] Fallback JSON loaded successfully!")
        } catch {
            print("🛑 [LifeQuest] Fallback JSON decode error: \(error)")
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
// MARK: - App Playgrounds Fallback JSON
private let fallbackJSON = """
{
  "paths": {
    "scholar": [
      {
        "id": "sch-01",
        "text": "وصلت المطار وحقائبك ثقيلة وقلبك أثقل. المدينة غريبة والأضواء ساطعة تتحدث بلغة لا تعرفها. مكتب الاستقبال أمامك والتاكسيات خلفك.",
        "icon": "airplane.arrival",
        "mentorAdvice": "الانطباع الأول يحدد مسار الرحلة. شجاعة بسيطة الآن توفر عليك أشهراً من التردد.",
        "delayImpact": 0,
        "tags": [
          "first-impression",
          "social"
        ],
        "options": [
          {
            "id": "sch-01-a",
            "label": "أنعزل وأركب تاكسي للفندق مباشرة",
            "feedback": "الراحة مهمة، لكنك فوّت فرصة عمرية. الخطوة الأولى في الاندماج تعني الكثير.",
            "impact": {
              "resilience": -5,
              "skill": 0,
              "hidden": [
                {
                  "key": "caution",
                  "delta": 1
                }
              ]
            },
            "contextTags": [
              "cautious",
              "solo"
            ]
          },
          {
            "id": "sch-01-b",
            "label": "أسأل مكتب الاستعلامات بلغتهم — ولو بجمل بسيطة",
            "feedback": "شجاعة رائعة! كسرت حاجز اللغة من الدقيقة الأولى. هذه اللحظة ستتذكرها دائماً.",
            "impact": {
              "resilience": 10,
              "skill": 8,
              "hidden": [
                {
                  "key": "curiosity",
                  "delta": 1
                }
              ]
            },
            "contextTags": [
              "brave",
              "social"
            ]
          }
        ]
      },
      {
        "id": "sch-02",
        "text": "أول أسبوع في الجامعة: المادة صعبة والأستاذ يتكلم بسرعة. زملاؤك يبدون مرتاحين وكأنهم يعرفون كل شيء. لديك امتحان غداً.",
        "icon": "book.fill",
        "mentorAdvice": "الشعور بالجهل مؤقت؛ الكسل والصمت دائمان. اطلب المساعدة قبل أن يتراكم التأخير.",
        "delayImpact": 2,
        "tags": [
          "academic",
          "pressure"
        ],
        "options": [
          {
            "id": "sch-02-a",
            "label": "أذاكر وحدي طوال الليل وأتجاهل طلب المساعدة",
            "feedback": "الصمود مهم، لكن الاستمرار وحدك يُنهكك على المدى البعيد. التعاون ليس ضعفاً.",
            "impact": {
              "resilience": -8,
              "skill": 5,
              "hidden": [
                {
                  "key": "impulsivity",
                  "delta": 1
                },
                {
                  "key": "caution",
                  "delta": 1
                }
              ]
            },
            "contextTags": [
              "independent",
              "stubborn"
            ]
          },
          {
            "id": "sch-02-b",
            "label": "أرسل رسالة لزميل وأطلب منه جلسة مراجعة مشتركة",
            "feedback": "ممتاز! بناء شبكة علمية من الأسبوع الأول ميزة لا تُقدَّر. الذكاء الاجتماعي يفوق الذكاء الفردي.",
            "impact": {
              "resilience": 8,
              "skill": 10,
              "hidden": [
                {
                  "key": "empathy",
                  "delta": 1
                },
                {
                  "key": "curiosity",
                  "delta": 1
                }
              ]
            },
            "contextTags": [
              "collaborative",
              "social"
            ]
          }
        ]
      },
      {
        "id": "sch-03",
        "text": "منتصف الفصل الدراسي. عُرض عليك مشروع بحثي بجانب الدراسة — فرصة مرموقة، لكنه سيأكل وقت راحتك ونومك.",
        "icon": "brain.head.profile",
        "mentorAdvice": "كل فرصة كبرى تأتي مع تكلفة. الحكيم يقيس طاقته قبل أن يقول نعم.",
        "delayImpact": 3,
        "tags": [
          "opportunity",
          "burnout-risk"
        ],
        "options": [
          {
            "id": "sch-03-a",
            "label": "أقبل المشروع الفوراً — الفرص لا تتكرر",
            "feedback": "الحماس رائع. لكن تذكّر أن الإرهاق سيأتي لاحقاً. ابنِ نظام عمل واضحاً أولاً.",
            "impact": {
              "resilience": -10,
              "skill": 15,
              "hidden": [
                {
                  "key": "impulsivity",
                  "delta": 2
                }
              ]
            },
            "contextTags": [
              "ambitious",
              "impulsive"
            ]
          },
          {
            "id": "sch-03-b",
            "label": "أطلب أسبوعاً للتفكير ثم أحدد شروطاً واضحة قبل القبول",
            "feedback": "حكمة نادرة في سنك! وضع الحدود والتفاوض يظهر نضجاً يحترمه الآخرون.",
            "impact": {
              "resilience": 5,
              "skill": 8,
              "hidden": [
                {
                  "key": "caution",
                  "delta": 2
                },
                {
                  "key": "curiosity",
                  "delta": 1
                }
              ]
            },
            "contextTags": [
              "strategic",
              "cautious"
            ]
          }
        ]
      },
      {
        "id": "sch-04",
        "text": "زميلك طلب منك أن تنسب جزءاً من عملك له في التقرير النهائي — يقول إنه ساعدك بالأفكار شفهياً وأنتم أصدقاء.",
        "icon": "doc.text.magnifyingglass",
        "mentorAdvice": "الأمانة الأكاديمية أثمن من أي صداقة. ما تُبنى العلاقات الحقيقية إلا على الصدق.",
        "delayImpact": 0,
        "tags": [
          "ethics",
          "friendship"
        ],
        "options": [
          {
            "id": "sch-04-a",
            "label": "أوافق لتجنب التوتر — الصداقة أهم",
            "feedback": "قرار مفهوم عاطفياً، لكنه يُضعف نزاهتك العلمية ويفتح باباً لطلبات مستقبلية أكبر.",
            "impact": {
              "resilience": -5,
              "skill": -5,
              "hidden": [
                {
                  "key": "empathy",
                  "delta": 1
                },
                {
                  "key": "impulsivity",
                  "delta": 1
                }
              ]
            },
            "contextTags": [
              "conflict-avoidance"
            ]
          },
          {
            "id": "sch-04-b",
            "label": "أرفض بلطف وأشرح أن المساهمة الشفهية لا تُنسَب أكاديمياً",
            "feedback": "شجاعة أخلاقية! الرفض اللطيف مع التفسير الواضح يُظهر نضجاً وأمانة نادرَيْن.",
            "impact": {
              "resilience": 10,
              "skill": 5,
              "hidden": [
                {
                  "key": "caution",
                  "delta": 1
                },
                {
                  "key": "curiosity",
                  "delta": 1
                }
              ]
            },
            "contextTags": [
              "ethical",
              "assertive"
            ]
          }
        ]
      },
      {
        "id": "sch-05",
        "text": "نهاية الفصل — حصلت على تقييم جيد لكن أستاذك يرى أن لديك إمكانية أكبر. يعرض عليك التحضير لمسابقة دولية خلال الصيف.",
        "icon": "trophy.fill",
        "mentorAdvice": "الراحة ضرورة، والطموح نعمة. ابحث عن التوازن لا عن الإجهاد. القمة تُصعَد خطوة واحدة في كل مرة.",
        "delayImpact": 0,
        "tags": [
          "growth",
          "ambition"
        ],
        "options": [
          {
            "id": "sch-05-a",
            "label": "أقبل التحدي وأكرّس الصيف للمسابقة",
            "feedback": "شجاعة المضي قُدُماً ستُكافأ. فقط تذكّر أن تخصص أوقاتاً للراحة الحقيقية.",
            "impact": {
              "resilience": 5,
              "skill": 15,
              "hidden": [
                {
                  "key": "curiosity",
                  "delta": 2
                }
              ]
            },
            "contextTags": [
              "ambitious",
              "growth"
            ]
          },
          {
            "id": "sch-05-b",
            "label": "أشكر الأستاذ وأخطط لموسم الصيف بشكل متوازن",
            "feedback": "الراحة الواعية استثمار لا هروب. التوازن سيجعلك أكثر قدرة عند العودة.",
            "impact": {
              "resilience": 12,
              "skill": 5,
              "hidden": [
                {
                  "key": "caution",
                  "delta": 1
                },
                {
                  "key": "empathy",
                  "delta": 1
                }
              ]
            },
            "contextTags": [
              "balanced",
              "self-aware"
            ]
          }
        ]
      }
    ],
    "scout": [
      {
        "id": "sct-01",
        "text": "الطريق الصحراوي طويل والوقود بدأ ينفد. مؤشر الوقود في المنطقة الحمراء وأقرب محطة بعد 50 كيلومتراً.",
        "icon": "fuelpump.fill",
        "mentorAdvice": "في الصحراء، العجلة عدوك الأول. الموارد لا تُهدر والقرار الهادئ ينقذ الأرواح.",
        "delayImpact": 0,
        "tags": [
          "resource-management",
          "survival"
        ],
        "options": [
          {
            "id": "sct-01-a",
            "label": "أطفئ المكيف وأُهدئ السرعة للحفاظ على الوقود",
            "feedback": "حكمة الصحراء! الحفاظ على الموارد في اللحظات الحرجة فارق بين النجاة والهلاك.",
            "impact": {
              "resilience": 12,
              "skill": 8,
              "hidden": [
                {
                  "key": "caution",
                  "delta": 2
                }
              ]
            },
            "contextTags": [
              "cautious",
              "resourceful"
            ]
          },
          {
            "id": "sct-01-b",
            "label": "أزيد السرعة للوصول قبل نفاد الوقود",
            "feedback": "مخاطرة غير محسوبة! الإسراع يستهلك وقوداً أكثر. الضغط جعلك تتصرف عكس المنطق.",
            "impact": {
              "resilience": -15,
              "skill": -8,
              "hidden": [
                {
                  "key": "impulsivity",
                  "delta": 2
                }
              ]
            },
            "contextTags": [
              "impulsive",
              "risk"
            ]
          }
        ]
      },
      {
        "id": "sct-02",
        "text": "وصلت إلى تقاطع: الطريق المعبّد أطول بساعتين، والطريق الجبلي أقصر لكن غير معروف وخريطتك قديمة.",
        "icon": "map.fill",
        "mentorAdvice": "الطريق الأقصر دائماً يغري. لكن في البرية، المجهول يحمل ثمناً لا تراه على الخريطة.",
        "delayImpact": 2,
        "tags": [
          "navigation",
          "risk-assessment"
        ],
        "options": [
          {
            "id": "sct-02-a",
            "label": "أسلك الطريق الجبلي المجهول لتوفير الوقت",
            "feedback": "المغامرة أتت ثمارها هذه المرة — لكن المخاطرة بخريطة قديمة قد تكون مميتة في اليوم التالي.",
            "impact": {
              "resilience": 5,
              "skill": 5,
              "hidden": [
                {
                  "key": "impulsivity",
                  "delta": 1
                },
                {
                  "key": "curiosity",
                  "delta": 1
                }
              ]
            },
            "contextTags": [
              "adventurous",
              "risky"
            ]
          },
          {
            "id": "sct-02-b",
            "label": "أختار الطريق المعبّد الآمن وأحفظ طاقتي للغد",
            "feedback": "قرار ناضج. الوقت المُستغرَق في الأمان يُعوَّض؛ الإصابة في المجهول قد لا تُعوَّض.",
            "impact": {
              "resilience": 10,
              "skill": 5,
              "hidden": [
                {
                  "key": "caution",
                  "delta": 2
                }
              ]
            },
            "contextTags": [
              "safe",
              "strategic"
            ]
          }
        ]
      },
      {
        "id": "sct-03",
        "text": "أحد أفراد فريقك يُظهر إرهاقاً واضحاً لكنه يرفض الاعتراف ويصرّ على المواصلة. الجماعة تنتظر قرارك كقائد.",
        "icon": "person.2.fill",
        "mentorAdvice": "القائد الحقيقي يرى ما يخفيه أفراد فريقه عن أنفسهم. الرعاية ليست ضعفاً — هي قوة الفريق.",
        "delayImpact": 0,
        "tags": [
          "leadership",
          "empathy"
        ],
        "options": [
          {
            "id": "sct-03-a",
            "label": "أحترم رغبته وأواصل مع الفريق",
            "feedback": "احترام الرغبات مهم، لكن القائد مسؤول عن سلامة فريقه حتى حين يرفضون الاعتراف بضعفهم.",
            "impact": {
              "resilience": -5,
              "skill": 5,
              "hidden": [
                {
                  "key": "impulsivity",
                  "delta": 1
                }
              ]
            },
            "contextTags": [
              "conflict-avoidance",
              "respect"
            ]
          },
          {
            "id": "sct-03-b",
            "label": "أوقف الجماعة وأُعلن استراحة لمدة ساعة بصرف النظر عن رأيه",
            "feedback": "قيادة حقيقية! أحياناً القائد يحمي الناس من أنفسهم. فريقك سيشكرك لاحقاً.",
            "impact": {
              "resilience": 10,
              "skill": 8,
              "hidden": [
                {
                  "key": "empathy",
                  "delta": 2
                },
                {
                  "key": "caution",
                  "delta": 1
                }
              ]
            },
            "contextTags": [
              "empathic",
              "decisive"
            ]
          }
        ]
      },
      {
        "id": "sct-04",
        "text": "عثرت على مخيم مهجور فيه مؤن ومياه — لكن مكتوب عليه 'خاص: ممتلكات حجز الطوارئ الإقليمي'. وفريقك عطشان.",
        "icon": "tent.fill",
        "mentorAdvice": "الضرورة تُبيح المحظور أحياناً — لكن الضمير يُحاسبك حتى في الصحراء. تصرّف بحكمة ومسؤولية.",
        "delayImpact": 0,
        "tags": [
          "ethics",
          "survival"
        ],
        "options": [
          {
            "id": "sct-04-a",
            "label": "آخذ الحاجة الأساسية فقط وأترك رسالة شكر مع وعد باسترداد",
            "feedback": "مثالي! الأخذ بالضرورة مع الشفافية والالتزام بالتعويض هو المعيار الأخلاقي الأمثل.",
            "impact": {
              "resilience": 8,
              "skill": 5,
              "hidden": [
                {
                  "key": "empathy",
                  "delta": 2
                },
                {
                  "key": "curiosity",
                  "delta": 1
                }
              ]
            },
            "contextTags": [
              "ethical",
              "responsible"
            ]
          },
          {
            "id": "sct-04-b",
            "label": "أرفض المساس بالممتلكات وأواصل البحث عن ماء بديل",
            "feedback": "الالتزام بالقانون حتى في الصعاب موقف نبيل. لكن في حالات البقاء الحرجة، الأولويات تختلف.",
            "impact": {
              "resilience": -8,
              "skill": 3,
              "hidden": [
                {
                  "key": "caution",
                  "delta": 2
                }
              ]
            },
            "contextTags": [
              "lawful",
              "rigid"
            ]
          }
        ]
      },
      {
        "id": "sct-05",
        "text": "اليوم الأخير من الرحلة. أمامك خياران: العودة بالطريق المعروف آمناً، أو اكتشاف مسار جديد يُكمل خريطة المنطقة للفرق القادمة.",
        "icon": "binoculars.fill",
        "mentorAdvice": "كل مستكشف يترك شيئاً للآتين من بعده. البطولة الحقيقية في ما تتركه لا فيما تأخذه.",
        "delayImpact": 0,
        "tags": [
          "legacy",
          "exploration"
        ],
        "options": [
          {
            "id": "sct-05-a",
            "label": "أختار اكتشاف المسار الجديد وتوثيقه للفرق القادمة",
            "feedback": "روح الاستكشاف الحقيقية! ما رسمته اليوم سيوجّه مستكشفين لسنوات قادمة. هذا هو الإرث.",
            "impact": {
              "resilience": 5,
              "skill": 15,
              "hidden": [
                {
                  "key": "curiosity",
                  "delta": 2
                },
                {
                  "key": "empathy",
                  "delta": 1
                }
              ]
            },
            "contextTags": [
              "legacy",
              "curious",
              "brave"
            ]
          },
          {
            "id": "sct-05-b",
            "label": "أعود بالطريق الآمن المعروف — أمان الفريق أولاً",
            "feedback": "قرار حكيم ومسؤول. أمان فريقك دائماً فوق أي اكتشاف. العودة سالمين هي النصر الحقيقي.",
            "impact": {
              "resilience": 12,
              "skill": 5,
              "hidden": [
                {
                  "key": "caution",
                  "delta": 1
                },
                {
                  "key": "empathy",
                  "delta": 2
                }
              ]
            },
            "contextTags": [
              "protective",
              "responsible"
            ]
          }
        ]
      }
    ]
  }
}
"""
