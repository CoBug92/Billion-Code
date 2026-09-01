# Подпись приложения через Fastlane Match

- Статус конфигурации: реализована локально
- Статус внешней проверки: не выполнялась
- Последнее обновление: 2026-09-01

## Назначение и границы

Fastlane Match управляет development- и App Store-сертификатами и provisioning profiles для `ru.kostyuchenko.billion-code`. Signing-контур отделён от `generate`, `lint`, `test` и unsigned `build`: отсутствие Apple credentials не должно мешать обычной локальной разработке.

Конфигурация не создаёт Apple Developer resources сама по себе. Внешние изменения происходят только при явном запуске `signing_create`. Команда `signing_sync` работает в `readonly`-режиме и не создаёт сертификаты или profiles.

## Зависимости

- Apple Developer Program membership и доступ к нужной Team;
- зарегистрированный App ID `ru.kostyuchenko.billion-code`;
- отдельный приватный Git repository для зашифрованного Match storage;
- Ruby/Bundler и Fastlane из `Gemfile.lock`;
- доступ к Git repository по SSH agent или credential manager.

Signing repository не должен совпадать с репозиторием приложения. Fastlane хранит в нём зашифрованные сертификаты и profiles; `MATCH_PASSWORD` не хранится рядом с данными.

## Настройки

Несекретный Team ID задаётся в tracked `scripts/.env`:

```sh
TEAM_ID="ВАШ_TEAM_ID"
```

Остальные значения передаются окружением или password manager:

| Переменная | Назначение | Секрет |
|---|---|---|
| `MATCH_GIT_URL` | SSH/HTTPS URL приватного signing repository без встроенного token | нет, но может раскрывать инфраструктуру |
| `MATCH_GIT_BRANCH` | Ветка Match storage; по умолчанию `main` | нет |
| `MATCH_PASSWORD` | Пароль шифрования Match repository | да |
| `APPLE_ID` | Apple ID участника Developer Team | персональные данные |

Не добавлять `MATCH_PASSWORD`, Apple session, пароль Apple ID или private keys в `scripts/.env`, shell scripts, Fastfile, Git и логи CI.

## Установка зависимостей

```sh
bundle install
bundle check
```

Используется зафиксированный Fastlane 2.238.0. Все команды проекта запускают его через `bundle exec`.

## Создание сертификатов и profiles

После задания `TEAM_ID`, `MATCH_GIT_URL`, `MATCH_PASSWORD` и `APPLE_ID`:

```sh
make signing-create-development
make signing-create-appstore
```

Первая команда создаёт или обновляет development certificate/profile, вторая — distribution certificate и App Store profile. Обе команды могут изменить Apple Developer account и Match repository. Перед первым запуском следует убедиться, что выбраны правильные Team, Bundle ID и пустой либо предназначенный для этого приложения signing repository.

Конфигурация намеренно не предоставляет `match nuke` и не отзывает существующие сертификаты.

## Получение существующих profiles

Для новой рабочей машины или CI, когда создавать ничего не нужно:

```sh
make signing-sync-development
make signing-sync-appstore
```

Эти команды запускают Match с `readonly: true`. Если нужных данных в signing repository нет, операция завершается ошибкой вместо создания новых ресурсов.

## Прямой вызов lane

```sh
./scripts/fastlane/run ios signing_sync type:development
./scripts/fastlane/run ios signing_create type:appstore
```

Поддерживаются только `development` и `appstore`. Preflight требует непустые `APPLE_ID`, `BUNDLE_ID`, `TEAM_ID`, `MATCH_GIT_URL` и `MATCH_PASSWORD` до обращения к Match.

## Ошибки и восстановление

- `Не заданы переменные` — заполнить только перечисленные значения, не переносить секреты в tracked файлы.
- Нет доступа к Git — проверить SSH agent/token и права на отдельный signing repository.
- Apple authentication/2FA failed — обновить локальную Apple session или способ аутентификации, не сохранять пароль Apple ID в проекте.
- Profile не найден при sync — сначала уполномоченный владелец запускает соответствующий `signing_create`.
- Certificate limit reached — не отзывать сертификаты автоматически; сначала провести аудит активных сертификатов и пользователей.

## Что ещё не подтверждено

Локально проверены Ruby-синтаксис, Bundler lock, обнаружение lane и остановка preflight до внешнего вызова. Реальные Git clone/push, Apple authentication, создание сертификатов, установка profiles в keychain и signed archive не запускались.

## Связанные файлы

- `scripts/fastlane/Appfile`
- `scripts/fastlane/Fastfile`
- `scripts/fastlane/Matchfile`
- `scripts/fastlane/run`
- `Gemfile` и `Gemfile.lock`
- [Инженерные правила](project-guidelines.md)
