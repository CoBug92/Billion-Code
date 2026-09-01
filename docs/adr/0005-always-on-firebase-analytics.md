# ADR-0005: hardened always-on Firebase Analytics

- Статус: `accepted`
- Дата: 2026-08-31
- Decision register: P-015, B-003

## Контекст

Закрытый TestFlight должен проверить активацию, глубину исследования, завершение сюжета и возвращение. Без событий выборка в 50–100 человек даст только интервью и субъективные впечатления. Одновременно Firebase добавляет сбор технических данных и privacy obligations.

## Рассмотренные варианты

1. Не собирать продуктовую аналитику.
2. Consent/opt-out перед сбором.
3. Постоянно включённый, минимизированный и жёстко типизированный Firebase Analytics.
4. Собственная analytics infrastructure.

## Решение

В QA, TestFlight и Release используется Firebase Apple SDK 12.17.0 через SPM и продукт `FirebaseAnalyticsCore`. AdSupport не подключается; IDFV collection, automatic screen reporting и advertising personalization отключаются соответствующими Boolean keys в `Info.plist`.

Собственные события ограничены закрытым allowlist. Имена, email, URL, поисковые строки и свободный текст запрещены. Debug, previews, unit- и UI-tests используют Noop/spy.

Consent и пользовательский opt-out в MVP отсутствуют. Firebase app-instance ID существует и не называется анонимным.

## Последствия

Положительные:

- количественные критерии TestFlight измеримы;
- типизированный allowlist ограничивает случайную утечку контента/PII;
- аналитика не проникает во feature layer.

Отрицательные:

- приложение не является продуктом без идентификаторов и telemetry;
- auto-collected Firebase events выходят за рамки custom allowlist;
- решение создаёт legal/privacy работу и может ограничить географию запуска;
- пользователь не может отказаться от аналитики внутри приложения.

## Обязательные меры

- `PrivacyInfo.xcprivacy` и manifests SDK;
- privacy policy и App Store privacy disclosure;
- проверка Xcode privacy report фактического archive;
- проверка отсутствия AdSupport/IDFV;
- документирование auto-collected events отдельно от custom events;
- review сроков хранения и регионов обработки.

Невыполнение этих мер блокирует публичный релиз, но не документацию и локальный технический prototype.

## Связанные документы

- [Privacy и аналитика](../tech/privacy-analytics.md)
- [TestFlight-валидация](../product/mvp-validation.md)
- [Firebase Apple SDK releases](https://github.com/firebase/firebase-ios-sdk/releases)
