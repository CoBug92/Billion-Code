# ADR-0006: HTTPS origin и checksum без подписанного manifest

- Статус: `accepted`
- Дата: 2026-09-01
- Decision register: P-016

## Контекст

Клиент загружает исполняемо неактивный, но пользовательски значимый редакционный dataset. Нужно обнаруживать сетевое повреждение, partial download и несоответствие payload. Подписанный manifest добавил бы key management, rotation, revocation и recovery, которые пока не соответствуют MVP threat model.

## Рассмотренные варианты

1. Только HTTPS без checksum.
2. ATS HTTPS, controlled/allowlisted origins и SHA-256 manifest payload.
3. Цифровая подпись manifest с ключом, встроенным в приложение.

## Решение

MVP использует только HTTPS через ATS, compile-time/manifest allowlist hosts, максимум три контролируемых redirect и SHA-256 точных загруженных dataset bytes. Immutable dataset URL содержит hash. Manifest ограничен 128 KiB, dataset — 5 MiB, timeout — 15 секунд.

SHA-256 здесь является проверкой целостности и адресацией контента. Это не authentication и не защита от злоумышленника, получившего контроль над hosting/CDN/account и заменившего одновременно manifest и payload.

Signed manifest не входит в MVP. Его добавление требует нового threat model и ADR.

## Последствия

Положительные:

- повреждённый/частичный payload не активируется;
- реализация существенно проще signature infrastructure;
- immutable hashes упрощают cache и rollback.

Отрицательные:

- компрометация origin/account остаётся доверенным каналом для клиента;
- безопасность зависит от ATS, TLS, account security и publication permissions;
- allowlist и redirects требуют явных сетевых тестов.

## Инварианты и проверки

- HTTP запрещён.
- Каждый redirect повторно проверяется до чтения body.
- Size limit применяется во время загрузки, не после удержания всего body в памяти.
- Checksum считается по точным скачанным байтам до decode.
- Mismatch удаляет temp и не меняет current pointer.
- URL, checksum и content body не отправляются в analytics.

Переход к подписи рассматривается при увеличении аудитории, появлении особо чувствительных данных, недоверенного publication path или требования защиты от CDN/account compromise.

## Связанные документы

- [Content delivery](../tech/content-delivery.md)
- [Manifest schema](../contracts/manifest-v1.schema.json)
- [ADR-0002: offline feed](0002-offline-content-feed.md)
