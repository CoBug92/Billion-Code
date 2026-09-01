# Шаблон профиля и первый состав

- Статус шаблона: `accepted`
- Статус персон: `candidate — feasibility screened`
- Публикационный статус: `blocked for publication`
- Последнее обновление: 2026-09-01

## Назначение

Документ задаёт минимальную глубину одного профиля и кандидатный состав MVP. Включение имени в таблицу не подтверждает конкретную сумму, факт, связь, лицензию или право на изображение.

## Шаблон исследования

### Идентификация

- каноническое имя и варианты написания;
- дата рождения и гражданство только при достаточном основании;
- краткая нейтральная роль;
- лицензированный портрет.

### Оценка состояния

- amount USD;
- as-of date;
- publisher и methodology note;
- основные компоненты;
- условия использования конкретной суммы.

### Происхождение капитала

- стартовые условия;
- наследство и ранняя поддержка;
- ключевые компании и доли;
- решения, повлиявшие на рост;
- вклад партнёров и внешних условий;
- различие созданной, полученной и сохраняемой стоимости.

### Таймлайн

Минимум шесть date-only событий. Событие включается, если меняет объяснение карьеры, собственности, капитала или сети.

### Образование

Для каждого учреждения фиксируются период, `attended/graduated/degree`, название степени и source.

### Связи

Минимум пять evidence-linked relationships к разным сущностям. Общий узел не преобразуется в личную связь.

### Споры

Включаются только материальные для истории капитала, контроля или сети события. Статус и позиция другой стороны обязательны.

### Редакционная проверка

- автор/редактор;
- дата полного review;
- claims высокого риска;
- media audit;
- licensing decision;
- ожидаемая дата следующего review.

## Допуск профиля

Профиль проходит в MVP только если одновременно выполнены условия:

1. Есть законно используемая датированная оценка состояния.
2. Есть лицензированный портрет.
3. Подтверждён точный статус образования или честно зафиксировано отсутствие данных.
4. Подготовлено минимум шесть событий.
5. Есть минимум пять доказательных рёбер.
6. Все material/sensitive claims прошли стандарт источников.
7. Измерена редакционная трудоёмкость.
8. Schema и domain validator принимают материал.

## Основной кандидатный состав

### Граница проведённого аудита

1 сентября 2026 года выполнен только source-feasibility screening: найден ли первичный маршрут к центральным ролям/ownership и есть ли материал для доказательного графа. Это не claim audit и не разрешение на публикацию. Суммы состояния, образование, минимум шесть событий, пять связей и портреты ещё не проверены поштучно.

`Graph potential` ниже — редакционная оценка, а не измеренный факт. Company IR и annual reports являются первичными источниками ролей и ownership, но могут быть заинтересованными источниками биографического нарратива; для material/sensitive claims требуется независимое авторитетное освещение.

| Приоритет | Персона | Первичный source route | Главный риск следующего аудита | Screening |
|---:|---|---|---|---|
| 1 | Elon Musk | [Tesla IR: roles, компании, образование](https://ir.tesla.com/corporate/elon-musk) | Частные активы и чувствительные claims усложняют состав капитала; graph potential высокий | `screened-continue` |
| 2 | Larry Page | [Alphabet IR: cofounder, shareholder, board](https://abc.xyz/investor/news/news-details/2019/Alphabet-management-change-12-03-2019/default.aspx) | Доли и роли должны иметь собственные as-of даты; overlap с Brin высокий | `screened-continue` |
| 3 | Sergey Brin | [Alphabet IR: cofounder, shareholder, board](https://abc.xyz/investor/news/news-details/2019/Alphabet-management-change-12-03-2019/default.aspx) | Нельзя дублировать профиль Page; нужна самостоятельная редакционная ось | `screened-continue` |
| 4 | Jeff Bezos | [Amazon IR: reports, proxies, shareholder letters](https://ir.aboutamazon.com/annual-reports-proxies-and-shareholder-letters/default.aspx) | Публичные и частные компоненты капитала требуют разных методик | `screened-continue` |
| 5 | Mark Zuckerberg | [Meta Investor: financials и filings](https://investor.atmeta.com/financials/) | Контроль и sensitive controversies требуют разделять filing, позицию компании и независимые sources | `screened-continue` |
| 6 | Jensen Huang | [NVIDIA IR: reports и proxy](https://investor.nvidia.com/financial-info/financial-reports-and-proxy-information/default.aspx) | Нужен timeline, который объясняет путь, а не пересказывает динамику акции | `screened-continue` |
| 7 | Bill Gates | [Microsoft archive](https://www.microsoft.com/en-us/investor/annual-reports) | Текущий капитал нельзя автоматически сводить к Microsoft; philanthropy требует отдельной модели | `screened-continue` |
| 8 | Steve Ballmer | [Microsoft historical annual reports](https://www.microsoft.com/en-us/investor/annual-reports) | История employee/executive должна быть доказана историческими filings, а не ретроспективными пересказами | `screened-continue` |
| 9 | Warren Buffett | [Berkshire reports и shareholder letters](https://www.berkshirehathaway.com/) | Leadership transition и as-of ownership нужно фиксировать по датам | `screened-continue` |
| 10 | Bernard Arnault | [LVMH biography и governance](https://www.lvmh.com/en/our-group/governance/bernard-arnault) | Семейные holdings, личная и групповая ownership не взаимозаменяемы | `screened-continue` |
| 11 | Alice Walton | [Walmart beneficial-ownership filing](https://stock.walmart.com/sec-filings/all-sec-filings/content/0001140361-25-002729/ef20039847_ex1.htm) | Недавние изменения семейной структуры требуют датированного ownership graph | `screened-continue` |
| 12 | Françoise Bettencourt Meyers | [L’Oréal 2025 shareholder structure](https://www.loreal-finance.com/fr/document-enregistrement-universel-2025/fr/article/395/) | Семья, личная доля и holdings должны быть отдельными сущностями | `screened-continue` |
| 13 | Mukesh Ambani | [Reliance 2024–25 integrated report](https://www.ril.com/ar2024-25/index.html) | Наследование и control across group требуют индийских filings и независимой проверки | `screened-continue` |
| 14 | Gautam Adani | [Adani statutory report](https://connect.adani.com/annual_report/2025/apsez/pdf/statutory-reports.pdf) | Высокая чувствительность: company narrative недостаточен для спорных claims | `screened-continue` |
| 15 | Rafaela Aponte-Diamant | [MSC ownership transfer, 2026](https://www.msc.com/ar/newsroom/press-releases/2026/april/msc-mediterranean-shipping-company-announces-ownership-transfer) | Private company: сообщение MSC о transfer от Gianluigi к детям не объясняет долю Rafaela и требует согласования с [текущей атрибуцией Forbes](https://www.forbes.com/profile/rafaela-aponte-diamant/) | `screened-hold` |

Список кураторский и не должен называться буквальным мировым топ-15.

### Вывод preliminary audit

- 14 кандидатов имеют достаточный первичный source route, чтобы начинать claim-level audit.
- Ни один профиль пока не имеет статуса `accepted-for-mvp`: wealth licensing и media clearance не выполнены.
- Rafaela Aponte-Diamant остаётся в списке только как проверяемый кандидат. До согласования current ownership с источниками и законного wealth estimate её место занимает первый прошедший резерв.
- Высокая концентрация US tech — сознательный недостаток текущего набора. После первых пяти карточек нужно измерить фактическую редакционную стоимость и при необходимости заменить дублирующий профиль Page/Brin кандидатом из другого региона/сектора.
- Уверенность screening: средняя для пригодности source routes, низкая для финальной публикуемости.

## Резерв

| Порядок замены | Персона | Возможная роль |
|---:|---|---|
| 1 | Larry Ellison | Founder/ownership и технологические связи |
| 2 | Michael Dell | Публично-частная трансформация компании |
| 3 | Amancio Ortega | Retail и структура частного/публичного капитала |
| 4 | Carlos Slim | Телеком, региональная диверсификация и конгломерат |

Если основной кандидат не проходит любой обязательный gate, используется первый прошедший аудит кандидат из резерва. Замена фиксируется в [реестре решений](../decisions.md) как редакционное решение, а не незаметное изменение списка.

## Матрица аудита

Для каждого кандидата создаётся рабочая карточка со статусами:

| Область | Допустимые статусы |
|---|---|
| Wealth source | `not-started`, `candidate`, `licensed/allowed`, `blocked` |
| Portrait | `not-started`, `candidate`, `cleared`, `blocked` |
| Timeline | `0–5`, `ready ≥ 6` |
| Relationships | `0–4`, `ready ≥ 5` |
| Education | `verified`, `partial`, `unknown` |
| Sensitive review | `not-needed`, `pending`, `passed`, `blocked` |
| Domain validation | `pending`, `passed`, `failed` |
| Final status | `candidate`, `accepted-for-mvp`, `rejected`, `reserve` |

Текущий `screened-continue` означает только разрешение начать полный audit. Он не заменяет ни один статус матрицы и не снимает publication blockers.

## Definition of done профиля

- [ ] Все обязательные секции заполнены.
- [ ] Ровно одна актуальная wealth estimate выбрана для отображения.
- [ ] Story не противоречит структурированным claims.
- [ ] Timeline имеет минимум шесть точных дат.
- [ ] Relationships соответствуют графовой семантике.
- [ ] Все источники открываются и датированы.
- [ ] Media rights подтверждены.
- [ ] Sensitive review завершён.
- [ ] Редакторская стоимость записана.
- [ ] Профиль проходит schema и domain validation.
