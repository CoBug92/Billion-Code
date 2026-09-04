# Код миллиарда

«Код миллиарда» — проект нативного iPhone-приложения о происхождении крупнейших состояний и доказуемых связях между людьми, компаниями, университетами, фондами, семьями и сделками.

В репозитории находятся каноническая документация и нативный технический spike. Текущий root screen показывает единую Obsidian-подобную сеть из людей, компаний и университетов с pan/zoom и подсветкой подтверждённых временных пересечений. Расширенный fixture предназначен только для локальной оценки дизайна и производительности: полноценный MVP и готовый к публикации редакционный контент ещё не реализованы.

## Зафиксированные идентификаторы

- Публичное русское название: **«Код миллиарда»**
- Xcode-проект, target и Swift-модуль: `BillionCode`
- Bundle ID: `ru.kostyuchenko.billion-code`
- Английское публичное название: не определено

## Документация

- [Оглавление и маршруты чтения](docs/index.md)
- [Продуктовое видение](docs/product/vision.md)
- [Требования к MVP](docs/product/requirements.md)
- [Предлагаемая iOS-архитектура](docs/tech/ios-architecture.md)
- [Подпись приложения через Fastlane Match](docs/engineering/signing.md)
- [Реестр решений](docs/decisions.md)

## Локальная разработка

Требуются версии инструментов, закреплённые в `.xcode-version` и `Mintfile`.

```sh
./scripts/generate
./scripts/lint
./scripts/test
./scripts/build
```

`test` и `build` требуют доступного iOS Simulator runtime. Сгенерированный `BillionCode.xcodeproj` вручную не редактируется.

Fastlane Match настроен отдельно от unsigned-сборки. Подготовка signing repository и команды создания provisioning profiles описаны в [руководстве по подписи](docs/engineering/signing.md).

## Текущие границы

Документация описывает желаемый MVP и решения, принятые 31 августа — 3 сентября 2026 года. Единая evidence network является presentation experiment и не меняет schema v1. Renderer и `ContentStore` остаются `proposed` до performance/accessibility audit и fault injection. Лицензирование оценки состояния и изображений имеет статус `blocked for publication`.
