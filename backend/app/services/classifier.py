"""Keyword-based transaction classifier."""

INCOME_RULES: list[tuple[str, list[str]]] = [
    ("freelance",    ["разработка", "дизайн", "верстка", "программирование", "сайт", "приложение", "код", "dev", "design"]),
    ("consulting",   ["консультация", "консалтинг", "аудит", "анализ", "экспертиза", "совет"]),
    ("content",      ["контент", "текст", "копирайтинг", "статья", "пост", "smm", "reels", "youtube", "twitch"]),
    ("teaching",     ["урок", "репетитор", "курс", "обучение", "тренинг", "лекция"]),
    ("sales",        ["продажа", "товар", "магазин", "shop", "store", "маркетплейс", "wildberries", "ozon"]),
    ("services",     ["услуга", "работа", "выполнен", "заказ", "проект"]),
]

EXPENSE_RULES: list[tuple[str, list[str]]] = [
    ("software",     ["подписка", "subscription", "saas", "figma", "notion", "slack", "adobe", "jetbrains", "github"]),
    ("marketing",    ["реклама", "таргет", "промо", "продвижение", "яндекс директ", "google ads"]),
    ("office",       ["офис", "аренда", "коворкинг", "оборудование", "мебель"]),
    ("taxes",        ["налог", "npd", "усн", "патент", "взнос", "пфр", "фсс"]),
    ("salary",       ["зарплата", "оклад", "выплата", "фриланс исполнитель"]),
    ("transport",    ["такси", "метро", "транспорт", "uber", "яндекс go", "бензин"]),
    ("food",         ["кафе", "ресторан", "обед", "еда", "продукты", "кофе"]),
    ("education",    ["курс", "обучение", "книга", "конференция", "митап"]),
]


def classify(description: str, direction: str) -> str | None:
    text = description.lower()
    rules = INCOME_RULES if direction == "income" else EXPENSE_RULES
    for category, keywords in rules:
        if any(kw in text for kw in keywords):
            return category
    return None
