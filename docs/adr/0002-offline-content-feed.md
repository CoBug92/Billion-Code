# ADR-0002: offline-first content feed и атомарный snapshot

- Статус: `proposed`
- Дата: 2026-09-01
- Decision register: T-003

## Контекст

Редакционный контент должен открываться сразу, переживать сетевые ошибки и обновляться без публикации новой версии приложения. Partial, corrupted или несовместимый dataset не должен попадать в UI. Для MVP не нужна изменяемая пользовательская база данных.

## Рассмотренные варианты

1. Всегда читать JSON из сети при запуске.
2. Использовать SwiftData как основной content store.
3. Bundled seed плюс immutable validated file snapshots `current → previous → seed`.

## Предлагаемое решение

Actor-isolated `ContentStore` публикует только immutable `ContentSnapshot`. Bootstrap использует current, затем previous, затем bundled seed. Foreground refresh не чаще раза в шесть часов загружает данные во временный файл, проверяет размер/checksum/schema/domain invariants вне `MainActor` и только потом атомарно меняет current pointer.

Dataset хранится в Application Support без backup; изображения — в purgeable Caches. Background task в MVP отсутствует. SwiftData для immutable content не используется.

Решение становится `accepted` после cache/update spike с fault injection.

## Последствия

Положительные:

- первый render не зависит от сети;
- невалидный release не уничтожает рабочую версию;
- rollback не требует app update;
- domain UI не зависит от transport DTO.

Отрицательные:

- нужны собственные atomic pointer, garbage collection и corruption recovery;
- seed увеличивает bundle;
- одновременно могут храниться несколько payload;
- требуется строгая parity publisher/consumer validators.

## Риски и проверка

Spike обязан воспроизвести timeout, cancellation, redirect, partial download, checksum mismatch, unsupported schema, current corruption, concurrent refresh, disk full и interruption по обе стороны swap. Пока это не выполнено, документ описывает намерение, а не работающий механизм.

## Связанные документы

- [Доставка контента](../tech/content-delivery.md)
- [Content model](../domain/content-model.md)
- [Content schema](../contracts/content-v1.schema.json)
- [Инженерные правила](../engineering/project-guidelines.md)

