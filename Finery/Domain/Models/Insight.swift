import Foundation

struct Insight: Identifiable, Sendable {
    let id: UUID
    let type: InsightType
    let title: String
    let body: String
    let severity: InsightSeverity

    init(
        id: UUID = UUID(),
        type: InsightType,
        title: String,
        body: String,
        severity: InsightSeverity
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.body = body
        self.severity = severity
    }
}

enum InsightType: Sendable {
    case taxDeadline
    case limitWarning
    case incomeGrowth
    case lowMargin
    case concentrationRisk
}

enum InsightSeverity: Sendable {
    case info, warning, critical
}
