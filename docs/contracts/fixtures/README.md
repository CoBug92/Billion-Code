# Fixtures контракта

Fixtures разделены по уровню проверки.

## Valid bundles

- `valid/minimal.json` — минимальный полный bundle.
- `valid/full.json` — расширенный bundle с education и disputed relationship.
- `valid/manifest.json` — валидный manifest.

Оба content bundle должны пройти JSON Schema и domain validation. Они используют вымышленные сущности и не являются редакционными материалами.

## Schema-invalid fragments

Следующие файлы проверяются против указанного `$defs` из `content-v1.schema.json`:

| Файл | `$defs` | Ожидаемая ошибка |
|---|---|---|
| `invalid/unknown-enum.json` | `entity` | Неизвестный `kind` |
| `invalid/invalid-money-date.json` | `wealthEstimate` | Денежное значение не строка целых USD и неверная дата |
| `invalid/missing-source.json` | `claim` | Пустой `sourceIds` нарушает `minItems` |

Готовые wrapper schemas находятся в `wrappers/`; fragment не является полным content bundle.

## Domain-invalid mutations

`dangling-reference.json`, `duplicate-id.json` и `missing-layout-position.json` описывают JSON Pointer mutation поверх `valid/minimal.json`. Получившийся bundle структурно допустим и может пройти обычную JSON Schema, но обязан быть отклонён publisher и Swift domain validator с указанным `expectedError`.

Это разделение принципиально: стандартная JSON Schema не проверяет ссылочную целостность между массивами и уникальность элементов по отдельному полю ID.

## Pinned AJV-проверка

Каноническая версия документационного этапа — `ajv-cli@5.0.0`. Она запускается без установки dependency в репозиторий:

```bash
npx --yes ajv-cli@5.0.0 validate --spec=draft2020 --strict=true \
  -s docs/contracts/content-v1.schema.json \
  -d docs/contracts/fixtures/valid/minimal.json

npx --yes ajv-cli@5.0.0 validate --spec=draft2020 --strict=true \
  -s docs/contracts/content-v1.schema.json \
  -d docs/contracts/fixtures/valid/full.json

npx --yes ajv-cli@5.0.0 validate --spec=draft2020 --strict=true \
  -s docs/contracts/manifest-v1.schema.json \
  -d docs/contracts/fixtures/valid/manifest.json
```

Schema-invalid fragments должны завершаться ненулевым exit code:

```bash
npx --yes ajv-cli@5.0.0 validate --spec=draft2020 --strict=true \
  -r docs/contracts/content-v1.schema.json \
  -s docs/contracts/fixtures/wrappers/entity.schema.json \
  -d docs/contracts/fixtures/invalid/unknown-enum.json

npx --yes ajv-cli@5.0.0 validate --spec=draft2020 --strict=true \
  -r docs/contracts/content-v1.schema.json \
  -s docs/contracts/fixtures/wrappers/wealth-estimate.schema.json \
  -d docs/contracts/fixtures/invalid/invalid-money-date.json

npx --yes ajv-cli@5.0.0 validate --spec=draft2020 --strict=true \
  -r docs/contracts/content-v1.schema.json \
  -s docs/contracts/fixtures/wrappers/claim.schema.json \
  -d docs/contracts/fixtures/invalid/missing-source.json
```

Domain-invalid mutations проверяются не AJV, а publisher/Swift domain validator. Если обычный AJV отклонит mutation по дополнительной причине — например, exact duplicate через `uniqueItems` — domain test всё равно обязателен и должен вернуть ожидаемый `expectedError`.
