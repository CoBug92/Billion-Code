# Дорожная карта

- Статус: `proposed`
- Последнее обновление: 2026-09-01

Дорожная карта задаёт порядок снижения рисков, а не обещание дат или функций.

## Этап 0 — документация

Статус: завершён 2026-09-01.

Результат текущего этапа:

- продуктовые и UX-контракты;
- доказательная и лицензионная политика;
- transport schema и fixtures;
- предлагаемая iOS-архитектура;
- критерии технических spike и TestFlight.

На этом этапе не создавались Xcode-проект, publisher, CDN и Firebase project. Ограничение относилось к границе этапа 0 и не запрещает последующие spike.

## Этап 1 — технические spike

Статус: в работе с 2026-09-01.

### Граф

Проверить SwiftUI `Canvas` для рёбер и `Button` для узлов на сцене 40/80: pan, zoom, выбор, recenter, Dynamic Type, VoiceOver, Voice Control и Reduce Motion.

Фактически реализованы source-backed people-only сцена на 13 людях, детерминированная organic layout, pan/zoom/recenter, `Canvas`-рёбра, портретные `Button`-узлы с fallback, структурированный список связей и панель `collapsed/medium/expanded`. Synthetic 40/80 fixture сохранён для regression checks. Performance и ручной accessibility audit на simulator/device ещё не выполнены; постепенное раскрытие соседей отсутствует.

### ContentStore

Проверить actor isolation, decode/validation вне `MainActor`, атомарный swap, `current → previous → seed`, interruption и disk-full поведение.

Фактически реализованы actor-isolated orchestration, `current → previous → bundled seed`, graph-подвыборка immutable snapshot, ссылочная validation, content-addressed payload и атомарная запись указателей. Полный runtime JSON Schema v1 consumer не реализован. Disk-full, interruption, concurrent refresh и полный fault injection остаются незавершёнными.

Код spike не переносится автоматически в production. По результатам уточняются документы и ADR; провал spike может открыть выбор другой graph-технологии или storage-схемы.

## Этап 2 — редакционный proof

- провести лицензионный аудит источников оценок;
- подготовить 3 полностью проверенных профиля;
- собрать первую связанную world-сцену;
- измерить фактическое время и стоимость редакционной работы;
- проверить читаемость текста и доказательств без аналитики реальных пользователей.

## Этап 3 — нативный MVP

- развить созданный generated Xcode-проект до production composition;
- развить bundled design seed, graph и sources до трёх полностью проверенных профилей;
- добавить remote feed и hardened Firebase;
- пройти accessibility, privacy и content QA;
- выпустить закрытый TestFlight.

## Этап 4 — продуктовая итерация

Только после четырёхнедельной проверки выбрать одно направление:

- углубить редакционный атлас;
- упростить продукт до историй, если граф не создаёт ценности;
- расширить каталог, если удержание подтверждено;
- остановить или переформулировать продукт, если ценность одноразовая.

## Явно отложено

- монетизация;
- аккаунты и синхронизация;
- уведомления;
- шаринг и deep links;
- iPad/landscape;
- публичный App Store;
- сотни профилей;
- собственная real-time модель состояния;
- B2B и профессиональные workflows.
