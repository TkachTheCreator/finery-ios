import Foundation

struct ClassifyTransactionUseCase: Sendable {

    func execute(
        description: String,
        direction: TransactionDirection
    ) -> (income: IncomeCategory?, expense: ExpenseCategory?) {
        let text = description.lowercased()
        if direction == .income {
            return (classifyIncome(text), nil)
        } else {
            return (nil, classifyExpense(text))
        }
    }

    private func classifyIncome(_ text: String) -> IncomeCategory {
        if text.contains("boosty") || text.contains("бусти") {
            return .boosty
        }
        if text.contains("донат") || text.contains("donate") ||
           text.contains("donationalerts") || text.contains("стрим") {
            return .donations
        }
        if text.contains("реклам") || text.contains("интеграц") ||
           text.contains("спонсор") || text.contains("adv") {
            return .advertising
        }
        if text.contains("фриланс") || text.contains("за проект") ||
           text.contains("за дизайн") || text.contains("за разработк") {
            return .freelance
        }
        if text.contains("youtube") || text.contains("ютуб") ||
           text.contains("дзен") || text.contains("rutube") {
            return .platforms
        }
        if text.contains("курс") || text.contains("вебинар") ||
           text.contains("урок") || text.contains("репетитор") {
            return .education
        }
        return .other
    }

    private func classifyExpense(_ text: String) -> ExpenseCategory {
        if text.contains("adobe") || text.contains("figma") ||
           text.contains("notion") || text.contains("github") || text.contains("подписк") {
            return .tools
        }
        if text.contains("яндекс директ") || text.contains("таргет") ||
           text.contains("vk реклам") {
            return .advertising
        }
        if text.contains("dns") || text.contains("м.видео") ||
           text.contains("камер") || text.contains("микрофон") {
            return .equipment
        }
        if text.contains("монтаж") || text.contains("редактор") ||
           text.contains("команд") || text.contains("выплат") {
            return .team
        }
        if text.contains("яндекс еда") || text.contains("самокат") ||
           text.contains("доставк") || text.contains("пятёрочк") {
            return .food
        }
        if text.contains("яндекс такси") || text.contains("uber") ||
           text.contains("метро") || text.contains("ржд") {
            return .transport
        }
        if text.contains("мтс") || text.contains("билайн") ||
           text.contains("мегафон") || text.contains("интернет") {
            return .communication
        }
        return .other
    }
}
