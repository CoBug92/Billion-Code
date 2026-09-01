# Privacy и продуктовая аналитика

- Статус продуктового решения: `accepted`
- Статус интеграции: `proposed`, код и Firebase-проект отсутствуют
- SDK baseline: Firebase Apple SDK 12.17.0, продукт `FirebaseAnalyticsCore`
- Последнее обновление: 2026-09-01

## Назначение и границы

Документ задаёт минимальный контракт аналитики для закрытого TestFlight и публичного приложения. Он адресован продукту, iOS-инженерам и ответственному за privacy review.

Firebase включается без consent-экрана и пользовательского opt-out в QA, TestFlight и Release. Это принятое продуктовое решение, но не освобождает от privacy policy, App Store disclosure и проверки фактического privacy report. Debug, previews, unit- и UI-tests не отправляют события во внешний сервис.

Analytics не используется для:

- рекламного таргетинга;
- персонализации профилей;
- построения пользовательских досье;
- сбора поисковых запросов или прочего свободного текста;
- идентификации конкретного участника исследования.

## Конфигурация Firebase

Планируемая интеграция:

- Swift Package Manager;
- Firebase Apple SDK `12.17.0`;
- подключён только продукт `FirebaseAnalyticsCore`, без AdSupport;
- `GOOGLE_ANALYTICS_IDFV_COLLECTION_ENABLED=NO` (Boolean в `Info.plist`);
- `FirebaseAutomaticScreenReportingEnabled=NO` (Boolean в `Info.plist`);
- `GOOGLE_ANALYTICS_DEFAULT_ALLOW_AD_PERSONALIZATION_SIGNALS=NO` (Boolean в `Info.plist`);
- Firebase adapter создаётся только composition root;
- Debug, SwiftUI previews и тестовые targets получают `NoopAnalyticsClient` или spy;
- QA, TestFlight и Release получают production adapter.

Версия фиксируется в `Package.resolved`. Перед релизом список реально связанных SDK и продуктов сверяется с Xcode build report, а не только с декларацией проекта.

Firebase создаёт app-instance ID. Это псевдонимный идентификатор экземпляра приложения, а не доказательство анонимности пользователя; в документах и интерфейсе слово «анонимный» для него не используется.

## Закрытый allowlist custom events

| Event | Разрешённые параметры | Момент отправки |
|---|---|---|
| `featured_view` | `edition_id` | Человек дня впервые показан в сессии |
| `people_sheet_open` | `detent` | Нижняя панель открыта пользователем |
| `entity_open` | `entity_id`, `entity_kind`, `origin` | Карточка или профиль сущности открыт |
| `relationship_open` | `relationship_kind`, `relationship_status` | Открыта доказательная карточка связи |
| `source_open` | `source_tier`, `claim_kind` | Пользователь перешёл к источнику |
| `story_complete` | `person_id`, `completion_bucket` | Достигнут конец редакционного сюжета |
| `content_refresh` | `result`, `cache_state`, `error_code` | Завершилась попытка обновления |

Значения параметров — только закрытые enums или стабильные публичные content IDs. `completion_bucket` — coarse bucket, а не точный процент или время чтения.

## Запрещённые данные

Ни event name, ни параметры не содержат:

- имя пользователя, email, номер телефона или advertising ID;
- URL источника или изображения;
- поисковую строку;
- свободный текст, заголовок или фрагмент статьи;
- filesystem path, stack trace или текст сетевой ошибки;
- точную геолокацию, IP, контакты или содержимое устройства;
- точное время чтения конкретного утверждения.

Stable entity IDs допустимы только потому, что они идентифицируют публичный редакционный объект, а не пользователя. Новые события не отправляются до обновления этой таблицы и privacy review.

## Auto-collected events

Custom allowlist не равен полному набору Firebase data. Firebase SDK может собирать собственные события и технические атрибуты в зависимости от версии, конфигурации и платформы.

Перед каждым внешним релизом необходимо:

1. сверить актуальную документацию Firebase для auto-collected events;
2. проверить фактический DebugView/экспорт тестовой сборки;
3. проверить linked SDKs и Xcode privacy report;
4. обновить privacy policy и App Store privacy disclosure при расхождении;
5. остановить релиз, если отключение заявленного сбора не подтверждено.

В документации нельзя обещать «собираем только семь событий»: корректная формулировка — «приложение отправляет только семь собственных событий из allowlist; auto-collected данные Firebase описываются отдельно».

## Privacy artifacts перед релизом

Обязательны:

- актуальный `PrivacyInfo.xcprivacy` приложения и проверка manifests сторонних SDK;
- публичная privacy policy с назначением аналитики, сроком хранения и каналом обращения;
- заполненная App Store privacy disclosure;
- Xcode privacy report из фактического Release archive;
- проверка отсутствия AdSupport/IDFV и запрещённых параметров;
- отдельная оценка законодательства для выбранных стран распространения.

Конкретные сроки хранения и регионы обработки не зафиксированы: они зависят от будущей Firebase-конфигурации и являются блокером релиза до подтверждения.

## Ошибки и деградация

- Недоступность Firebase не блокирует UI и загрузку контента.
- Analytics adapter принимает типизированный event и молча отбрасывает неизвестные параметры в release build.
- В Debug нарушение allowlist приводит к assertion/test failure.
- Повторная отправка офлайн-событий не должна влиять на продуктовую логику.
- Analytics error не отображается пользователю.

## Проверки

До TestFlight:

- unit-тест каждого event mapping;
- spy-проверка отсутствия event при preview/test composition;
- негативные тесты запрещённых ключей и свободного текста;
- проверка всех трёх privacy keys в собранном bundle: IDFV, automatic screen reporting и ad personalization;
- инспекция linked frameworks на отсутствие AdSupport;
- реальная проверка событий тестовой QA-сборки.

До публичного релиза добавляются privacy artifacts, legal review и App Store disclosure.

## Источники и связанные решения

- [Firebase Apple SDK releases](https://github.com/firebase/firebase-ios-sdk/releases)
- [Firebase Analytics data collection](https://firebase.google.com/docs/analytics/configure-data-collection)
- [Apple privacy manifests](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files)
- [ADR-0005: always-on Firebase](../adr/0005-always-on-firebase-analytics.md)
- [TestFlight-валидация](../product/mvp-validation.md)
- [Инженерные правила](../engineering/project-guidelines.md)
