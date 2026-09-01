# ADR-0004: Git-authored content pipeline

- Статус: `accepted`
- Дата: 2026-08-31
- Decision register: P-013, P-014

## Контекст

Первые 15 профилей требуют reviewable истории изменений, claim-level sources и воспроизводимой публикации. Полноценная CMS до доказательства спроса увеличивает стоимость и добавляет authentication, backend и редакционный UI, не проверяя основную гипотезу.

## Рассмотренные варианты

1. Встроить весь контент в приложение и обновлять через App Store.
2. Сразу создать CMS и API.
3. Хранить editorial YAML/Markdown в Git, компилировать versioned JSON и раздавать статически.

## Решение

Редакционные материалы хранятся в Git как YAML/Markdown. Будущий publisher выполняет validation, deterministic compilation в JSON Schema v1, вычисляет SHA-256, публикует immutable payload/media и только после этого обновляет manifest.

JSON размещается в Cloudflare Pages, медиа — в Cloudflare R2. Это hosting decision, но клиент остаётся provider-agnostic и знает только HTTPS contract и allowlist.

Текущий этап не выполняет `git init`, не создаёт compiler и не настраивает Cloudflare.

## Последствия

Положительные:

- diff/review/rollback доступны без CMS;
- wire format отделён от удобного authoring format;
- контент обновляется без app release;
- hosting можно заменить без изменения domain layer.

Отрицательные:

- редактору нужен Git workflow или посредник-инженер;
- publisher становится критической частью публикации;
- cross-record invariants нельзя переложить только на JSON Schema;
- secrets, preview и publication permissions придётся спроектировать отдельно.

## Инварианты публикации

- YAML/Markdown не загружаются iOS-клиентом.
- DTO не считаются domain model до полной validation.
- Dataset immutable и content-addressed.
- Manifest публикуется последним.
- Python publisher и Swift reader используют одни golden fixtures.
- Лицензионные блокеры проверяются до external distribution, даже если schema технически валидна.

## Риски и меры

До реализации compiler фиксируются schema и fixtures. До публичного запуска необходимы staging preview, двухэтапный review, rollback drill, credential policy и audit первых 15 профилей.

## Связанные документы

- [Editorial policy](../editorial/evidence-policy.md)
- [Content model](../domain/content-model.md)
- [Content delivery](../tech/content-delivery.md)
- [Manifest schema](../contracts/manifest-v1.schema.json)

