# Инженерные правила будущего iOS-проекта

- Статус: `proposed`
- Фактическое состояние: scaffold и команды созданы; simulator build/test не подтверждены из-за недоступности CoreSimulatorService в текущей среде
- Последнее обновление: 2026-09-01

## Назначение и аудитория

Документ задаёт reproducible baseline для реализации. Он предназначен для iOS-инженеров и CI/release-инженеров. Генерация и lint уже существуют; успешный simulator build/test ещё требует проверки в среде с рабочим CoreSimulator.

## Toolchain baseline

| Компонент | Зафиксированная версия | Где закреплён |
|---|---:|---|
| Xcode | 26.2 | `.xcode-version` |
| Swift | 6.2.3 | версия из Xcode, Swift 6 language mode |
| XcodeGen | 2.46.0 | `Mintfile` |
| SwiftGen | 6.6.3 | `Mintfile` |
| SwiftLint | 0.65.0 | `Mintfile` |
| Fastlane | 2.238.0 | `Gemfile` и `Gemfile.lock` |
| Firebase Apple SDK | 12.17.0 | SPM dependency и `Package.resolved` |

Baseline и генерация проекта проверены локально 2026-09-01. Смена фиксированной версии оформляется отдельным изменением документации.

## Генерация проекта

- Источник project settings — tracked `scripts/xcodegen/Application.yml` и tracked `scripts/.env`.
- `BillionCode.xcodeproj` генерируется XcodeGen, вручную не редактируется и не коммитится.
- Public display name для русской локали — «Код миллиарда».
- Project, target и module — `BillionCode`.
- Bundle ID — `ru.kostyuchenko.billion-code`.
- Deployment target — iOS 18.0; devices — iPhone; orientations — portrait.
- `ITSAppUsesNonExemptEncryption=false`, пока приложение использует только exempt standard HTTPS и не добавляет собственную криптографию.
- Signing settings и `TEAM_ID` отделены от локальной unsigned build.

Файл `scripts/.env` содержит только несекретные tracked project constants. Credentials, certificates и API tokens туда не помещаются.

## Репозиторные артефакты

Коммитятся:

- YAML XcodeGen;
- `.xcode-version` и `Mintfile`;
- `Package.resolved`;
- SwiftGen-generated accessors;
- SwiftLint config;
- source, tests, resources и privacy manifest.
- `Gemfile`, `Gemfile.lock` и Fastlane-конфигурация без credentials.

Не коммитятся:

- сгенерированный `.xcodeproj`;
- DerivedData;
- локальные signing credentials;
- Firebase credentials, не предназначенные для client bundle;
- временные content payload и simulator data.

`GoogleService-Info.plist` рассматривается отдельно: он не является серверным секретом, но добавляется только вместе с настроенным Firebase project и документированным environment mapping.

## Команды проекта

Единая automation surface должна предоставить:

| Команда | Контракт |
|---|---|
| `generate` | Проверить tool versions, сгенерировать resources и `.xcodeproj` |
| `lint` | Запустить SwiftLint без скрытого auto-fix |
| `test` | Выбрать доступный iOS Simulator runtime и выполнить unit/UI tests |
| `build` | Выполнить unsigned Debug build для iOS Simulator |

Команды реализованы shell scripts в `scripts/`; `Makefile` предоставляет одноимённые цели.

Simulator destination не содержит захардкоженной версии runtime. Скрипт выбирает доступный iPhone simulator с поддерживаемой iOS, печатает выбранный destination и завершается понятной ошибкой, если runtime отсутствует.

## Swift и concurrency

- Swift 6 language mode и strict concurrency включаются с первого коммита кода.
- UI state и feature view models изолированы `@MainActor`.
- Network/cache coordination принадлежит actor.
- `Sendable` моделируется явно; `@unchecked Sendable` требует отдельного review с обоснованием.
- `Task.detached` применяется только для измеримо тяжёлой CPU/IO-работы с явной cancellation.
- Production code не маскирует concurrency warnings.

## Код и архитектурные границы

- SwiftUI view отображает состояние и отправляет user intent.
- DTO не попадают в View и ViewModel.
- Domain snapshot immutable после validation.
- Протокол создаётся на заменяемой границе, а не для каждого типа.
- SwiftData не используется для immutable editorial content.
- Firebase, filesystem и URLSession остаются в Infrastructure.
- Новая зависимость требует объяснения размера, лицензии, privacy и альтернатив.

## Ресурсы и локализация

- Канонический язык content schema v1 — `ru`.
- Пользовательские строки локализуются и доступны через SwiftGen.
- Generated SwiftGen output коммитится.
- Цвета и изображения получают семантические имена в asset catalog.
- Полное имя сущности хранится отдельно от визуально сокращённой строки.
- Accessibility labels не строятся конкатенацией непереводимых фрагментов.

## Тестовая пирамида

Минимальная future matrix:

- unit: date-only, money, person-of-day, DTO→domain, graph transform, event allowlist;
- schema/domain fixtures: valid, malformed, truncated, oversized, unsupported;
- network через `URLProtocol`: timeout, redirects, status, cancellation, checksum;
- filesystem: corruption, concurrent refresh, disk full, interruption, rollback;
- UI: главный граф, sheet, profile, relationship/source navigation;
- accessibility: `performAccessibilityAudit` плюс ручные VoiceOver, Voice Control, Switch Control и Reduce Motion;
- privacy: отсутствие AdSupport/IDFV, inspection privacy report;
- performance spike: 40 nodes/80 edges и dataset 5 MiB.

Python publisher и Swift consumer обязаны принимать и отклонять один набор golden fixtures.

## CI и signing

CI пока не создан. Fastlane Match настроен для локального read-only sync и явного создания development/App Store profiles. Match storage, Apple Developer credentials и encryption password задаются только через environment/credential manager; внешний signing operation ещё не выполнялся. Подробный контракт приведён в [руководстве по подписи](signing.md).

Будущий pipeline сначала выполняет version check, generation drift check, lint, test и unsigned build. Signing/TestFlight jobs отделены и требуют явных secrets/permissions.

Локальная проверка не зависит от Apple Development Team. Release archive не считается проверенным только потому, что unsigned simulator build успешен.

## Definition of done для scaffold

- чистая машина получает документированные pinned tools;
- `generate`, `lint`, `test`, `build` воспроизводимы;
- повторная генерация не меняет tracked files;
- `.xcodeproj` отсутствует в Git;
- Package.resolved и SwiftGen output присутствуют;
- strict concurrency включён;
- display name, technical name и bundle ID соответствуют register;
- Debug/previews/tests используют Noop analytics;
- README обновлён фактическими командами только после их появления.

## Связанные документы

- [Предлагаемая iOS-архитектура](../tech/ios-architecture.md)
- [Privacy и аналитика](../tech/privacy-analytics.md)
- [Decision register](../decisions.md)
- [ADR native iOS](../adr/0001-native-ios-first.md)
- [Fastlane Match и подпись](signing.md)
