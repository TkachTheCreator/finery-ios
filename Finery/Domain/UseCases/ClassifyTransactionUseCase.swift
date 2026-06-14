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
        if text.contains("boosty") || text.contains("бусти") || text.contains("boost") {
            return .boosty
        }
        if text.contains("донат") || text.contains("donate") || text.contains("donat") ||
           text.contains("donationalerts") || text.contains("стрим") || text.contains("tip") ||
           text.contains("поддержк") || text.contains("благодарн") {
            return .donations
        }
        if text.contains("реклам") || text.contains("интеграц") || text.contains("спонсор") ||
           text.contains("adv") || text.contains("партнёр") || text.contains("партнер") ||
           text.contains("промо") || text.contains("нативк") {
            return .advertising
        }
        if text.contains("фриланс") || text.contains("freelance") || text.contains("за проект") ||
           text.contains("за дизайн") || text.contains("за разработк") || text.contains("разработк") ||
           text.contains("дизайн") || text.contains("верстк") || text.contains("сайт") ||
           text.contains("оплата услуг") || text.contains("за работу") || text.contains("консультац") ||
           text.contains("услуг") || text.contains("задан") {
            return .freelance
        }
        if text.contains("youtube") || text.contains("ютуб") || text.contains("дзен") ||
           text.contains("rutube") || text.contains("tiktok") || text.contains("тикток") ||
           text.contains("vk") || text.contains("вк") || text.contains("telegram") ||
           text.contains("телеграм") || text.contains("монетизац") {
            return .platforms
        }
        if text.contains("курс") || text.contains("вебинар") || text.contains("урок") ||
           text.contains("репетитор") || text.contains("обучен") || text.contains("тренинг") ||
           text.contains("менторинг") || text.contains("лекц") {
            return .education
        }
        return .other
    }

    private func classifyExpense(_ text: String) -> ExpenseCategory {
        if text.contains("adobe") || text.contains("figma") || text.contains("notion") ||
           text.contains("github") || text.contains("подписк") || text.contains("jetbrains") ||
           text.contains("slack") || text.contains("canva") || text.contains("loom") ||
           text.contains("dropbox") || text.contains("хостинг") || text.contains("домен") ||
           text.contains("vps") || text.contains("cloud") || text.contains("сервис") {
            return .tools
        }
        if text.contains("яндекс директ") || text.contains("таргет") || text.contains("vk реклам") ||
           text.contains("google ads") || text.contains("myTarget") || text.contains("промоц") ||
           text.contains("реклам") {
            return .advertising
        }
        if text.contains("dns") || text.contains("м.видео") || text.contains("mvideo") ||
           text.contains("камер") || text.contains("микрофон") || text.contains("компьютер") ||
           text.contains("ноутбук") || text.contains("монитор") || text.contains("технику") ||
           text.contains("оборудован") || text.contains("iphone") || text.contains("ipad") ||
           text.contains("apple") {
            return .equipment
        }
        if text.contains("монтаж") || text.contains("редактор") || text.contains("команд") ||
           text.contains("выплат") || text.contains("зарплат") || text.contains("фрилансер") ||
           text.contains("аутсорс") || text.contains("исполнитель") {
            return .team
        }
        if text.contains("яндекс еда") || text.contains("самокат") || text.contains("доставк") ||
           text.contains("пятёрочк") || text.contains("магнит") || text.contains("вкусвилл") ||
           text.contains("кафе") || text.contains("ресторан") || text.contains("обед") ||
           text.contains("кофе") || text.contains("перекус") {
            return .food
        }
        if text.contains("яндекс такси") || text.contains("uber") || text.contains("метро") ||
           text.contains("ржд") || text.contains("аэрофлот") || text.contains("билет") ||
           text.contains("транспорт") || text.contains("самокат аренд") {
            return .transport
        }
        if text.contains("мтс") || text.contains("билайн") || text.contains("мегафон") ||
           text.contains("интернет") || text.contains("связь") || text.contains("телефон") ||
           text.contains("tele2") || text.contains("теле2") {
            return .communication
        }
        return .other
    }
}
