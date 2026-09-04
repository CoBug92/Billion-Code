# Документация «Кода миллиарда»

Здесь хранится каноническая продуктовая и предлагаемая техническая документация проекта. В репозитории также появился первый нативный technical spike; документы явно разделяют его фактическое поведение и ещё не реализованный MVP.

## Быстрые маршруты

### Продукт и редакция

1. [Видение и позиционирование](product/vision.md)
2. [Требования к MVP](product/requirements.md)
3. [Проверка ценности в TestFlight](product/mvp-validation.md)
4. [Редакционная и доказательная политика](editorial/evidence-policy.md)
5. [Шаблон профиля и первый состав](editorial/profile-template-and-roster.md)

### UX и iOS-разработка

1. [Спецификация пользовательского опыта](ux/experience.md)
2. [Доменная модель](domain/content-model.md)
3. [Предлагаемая iOS-архитектура](tech/ios-architecture.md)
4. [Доставка и обновление контента](tech/content-delivery.md)
5. [Privacy и аналитика](tech/privacy-analytics.md)
6. [Инженерные правила](engineering/project-guidelines.md)
7. [Подпись приложения через Fastlane Match](engineering/signing.md)

### Контракты и решения

- [JSON Schema набора контента](contracts/content-v1.schema.json)
- [JSON Schema manifest](contracts/manifest-v1.schema.json)
- [Fixtures и команды проверки](contracts/fixtures/README.md)
- [Реестр решений](decisions.md)
- [ADR-0001: native iOS](adr/0001-native-ios-first.md)
- [ADR-0002: offline content feed](adr/0002-offline-content-feed.md)
- [ADR-0003: evidence graph](adr/0003-evidence-graph.md)
- [ADR-0004: content pipeline](adr/0004-git-authored-content-pipeline.md)
- [ADR-0005: Firebase Analytics](adr/0005-always-on-firebase-analytics.md)
- [ADR-0006: HTTPS manifest trust](adr/0006-https-manifest-trust.md)
- [ADR-0007: редакционный атлас глав](adr/0007-chapter-atlas-renderer.md)
- [ADR-0008: единая evidence network в стиле Obsidian](adr/0008-obsidian-evidence-network.md)
- [Глоссарий](glossary.md)

## Продуктовые документы

- [Видение и позиционирование](product/vision.md)
- [Требования к MVP](product/requirements.md)
- [Проверка ценности](product/mvp-validation.md)
- [Дорожная карта](product/roadmap.md)
- [Исходное исследование гипотезы](hypotheses/billionaires-app.md)

## Статусы

- `accepted` — решение явно принято пользователем.
- `proposed` — желаемое техническое решение, ещё не подтверждённое реализацией.
- `hypothesis` — проверяемое продуктовое предположение.
- `blocked for publication` — не мешает документации или spike, но блокирует внешнее распространение.

Актуальный статус каждого решения и его источник приведены в [реестре решений](decisions.md).

## Статус локальной проверки документационного этапа 2026-09-01

- Все JSON-файлы проходят `jq`; локальные `$ref` существуют, regex patterns компилируются.
- Valid fixtures приняты, schema-invalid fragments и domain-invalid mutations отклонены read-only wire/domain проверкой.
- 93 относительные Markdown-ссылки разрешаются в существующие файлы.
- У шести Mermaid-блоков проверены fences и тип диаграммы. Локальный `mmdc` отсутствует, поэтому render-проверка ещё не выполнена.
- Pinned `ajv-cli@5.0.0` не удалось загрузить из-за недоступности npm registry в текущем sandbox. Точные команды и wrapper schemas находятся в [fixtures README](contracts/fixtures/README.md); формальная AJV-проверка остаётся pending.
- На момент завершения документационного этапа файлы вне `README.md` и `docs/` не создавались. После отдельного разрешения пользователя начат этап technical spike: текущий статус приведён в [дорожной карте](product/roadmap.md).
