// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
public enum L10n {
  public enum Content {
    /// Загружаем выпуск
    public static let loading = L10n.tr("Localizable", "content.loading", fallback: "Загружаем выпуск")
    public enum Error {
      /// Bundled seed не прошёл проверку. Переустановите приложение или соберите проект заново.
      public static let message = L10n.tr("Localizable", "content.error.message", fallback: "Bundled seed не прошёл проверку. Переустановите приложение или соберите проект заново.")
      /// Выпуск недоступен
      public static let title = L10n.tr("Localizable", "content.error.title", fallback: "Выпуск недоступен")
    }
  }
  public enum Graph {
    /// Человек дня
    public static let edition = L10n.tr("Localizable", "graph.edition", fallback: "Человек дня")
    /// Связи выбранного узла
    public static let relationships = L10n.tr("Localizable", "graph.relationships", fallback: "Связи выбранного узла")
    /// Graph
    public static let title = L10n.tr("Localizable", "graph.title", fallback: "Код миллиарда")
    public enum Card {
      /// Связей: %d
      public static func relationships(_ p1: Int) -> String {
        return L10n.tr("Localizable", "graph.card.relationships", p1, fallback: "Связей: %d")
      }
      public enum Show {
        /// Показать связи
        public static let relationships = L10n.tr("Localizable", "graph.card.show.relationships", fallback: "Показать связи")
      }
    }
    public enum Chapter {
      /// Следующая глава: %@
      public static func next(_ p1: Any) -> String {
        return L10n.tr("Localizable", "graph.chapter.next", String(describing: p1), fallback: "Следующая глава: %@")
      }
      /// Глава %d из %d
      public static func position(_ p1: Int, _ p2: Int) -> String {
        return L10n.tr("Localizable", "graph.chapter.position", p1, p2, fallback: "Глава %d из %d")
      }
      /// Предыдущая глава: %@
      public static func previous(_ p1: Any) -> String {
        return L10n.tr("Localizable", "graph.chapter.previous", String(describing: p1), fallback: "Предыдущая глава: %@")
      }
      public enum Next {
        /// Следующая глава
        public static let action = L10n.tr("Localizable", "graph.chapter.next.action", fallback: "Следующая глава")
      }
      public enum Previous {
        /// Предыдущая глава
        public static let action = L10n.tr("Localizable", "graph.chapter.previous.action", fallback: "Предыдущая глава")
      }
    }
    public enum Entity {
      /// Сделка
      public static let deal = L10n.tr("Localizable", "graph.entity.deal", fallback: "Сделка")
      /// Событие
      public static let event = L10n.tr("Localizable", "graph.entity.event", fallback: "Событие")
      /// Семья
      public static let family = L10n.tr("Localizable", "graph.entity.family", fallback: "Семья")
      /// Фонд
      public static let foundation = L10n.tr("Localizable", "graph.entity.foundation", fallback: "Фонд")
      /// Организация
      public static let organization = L10n.tr("Localizable", "graph.entity.organization", fallback: "Организация")
      /// Человек
      public static let person = L10n.tr("Localizable", "graph.entity.person", fallback: "Человек")
      /// Университет
      public static let university = L10n.tr("Localizable", "graph.entity.university", fallback: "Университет")
    }
    public enum Featured {
      /// Редакционный выпуск · граф связей
      public static let summary = L10n.tr("Localizable", "graph.featured.summary", fallback: "Редакционный выпуск · граф связей")
    }
    public enum Fixture {
      public enum Entity {
        public enum Deal {
          /// Сделка %d
          public static func name(_ p1: Int) -> String {
            return L10n.tr("Localizable", "graph.fixture.entity.deal.name", p1, fallback: "Сделка %d")
          }
          /// Сделка %d
          public static func shortName(_ p1: Int) -> String {
            return L10n.tr("Localizable", "graph.fixture.entity.deal.short_name", p1, fallback: "Сделка %d")
          }
          /// Существенная сделка
          public static let summary = L10n.tr("Localizable", "graph.fixture.entity.deal.summary", fallback: "Существенная сделка")
        }
        public enum Event {
          /// Событие %d
          public static func name(_ p1: Int) -> String {
            return L10n.tr("Localizable", "graph.fixture.entity.event.name", p1, fallback: "Событие %d")
          }
          /// Событие %d
          public static func shortName(_ p1: Int) -> String {
            return L10n.tr("Localizable", "graph.fixture.entity.event.short_name", p1, fallback: "Событие %d")
          }
          /// Событие, повлиявшее на капитал
          public static let summary = L10n.tr("Localizable", "graph.fixture.entity.event.summary", fallback: "Событие, повлиявшее на капитал")
        }
        public enum Family {
          /// Семья %d
          public static func name(_ p1: Int) -> String {
            return L10n.tr("Localizable", "graph.fixture.entity.family.name", p1, fallback: "Семья %d")
          }
          /// Семья %d
          public static func shortName(_ p1: Int) -> String {
            return L10n.tr("Localizable", "graph.fixture.entity.family.short_name", p1, fallback: "Семья %d")
          }
          /// Семейная группа
          public static let summary = L10n.tr("Localizable", "graph.fixture.entity.family.summary", fallback: "Семейная группа")
        }
        public enum Foundation {
          /// Фонд %d
          public static func name(_ p1: Int) -> String {
            return L10n.tr("Localizable", "graph.fixture.entity.foundation.name", p1, fallback: "Фонд %d")
          }
          /// Фонд %d
          public static func shortName(_ p1: Int) -> String {
            return L10n.tr("Localizable", "graph.fixture.entity.foundation.short_name", p1, fallback: "Фонд %d")
          }
          /// Филантропическая организация
          public static let summary = L10n.tr("Localizable", "graph.fixture.entity.foundation.summary", fallback: "Филантропическая организация")
        }
        public enum Organization {
          /// Компания %d
          public static func name(_ p1: Int) -> String {
            return L10n.tr("Localizable", "graph.fixture.entity.organization.name", p1, fallback: "Компания %d")
          }
          /// Компания %d
          public static func shortName(_ p1: Int) -> String {
            return L10n.tr("Localizable", "graph.fixture.entity.organization.short_name", p1, fallback: "Компания %d")
          }
          /// Организация в структуре капитала
          public static let summary = L10n.tr("Localizable", "graph.fixture.entity.organization.summary", fallback: "Организация в структуре капитала")
        }
        public enum Person {
          /// Предприниматель %d
          public static func name(_ p1: Int) -> String {
            return L10n.tr("Localizable", "graph.fixture.entity.person.name", p1, fallback: "Предприниматель %d")
          }
          /// Персона %d
          public static func shortName(_ p1: Int) -> String {
            return L10n.tr("Localizable", "graph.fixture.entity.person.short_name", p1, fallback: "Персона %d")
          }
          /// Участник предпринимательской сети
          public static let summary = L10n.tr("Localizable", "graph.fixture.entity.person.summary", fallback: "Участник предпринимательской сети")
        }
        public enum University {
          /// Университет %d
          public static func name(_ p1: Int) -> String {
            return L10n.tr("Localizable", "graph.fixture.entity.university.name", p1, fallback: "Университет %d")
          }
          /// Вуз %d
          public static func shortName(_ p1: Int) -> String {
            return L10n.tr("Localizable", "graph.fixture.entity.university.short_name", p1, fallback: "Вуз %d")
          }
          /// Подтверждённое место обучения
          public static let summary = L10n.tr("Localizable", "graph.fixture.entity.university.summary", fallback: "Подтверждённое место обучения")
        }
      }
      public enum Featured {
        /// Graph spike fixture
        public static let name = L10n.tr("Localizable", "graph.fixture.featured.name", fallback: "Алексей Воронцов")
        /// А. Воронцов
        public static let shortName = L10n.tr("Localizable", "graph.fixture.featured.short_name", fallback: "А. Воронцов")
        /// Основатель промышленной группы
        public static let summary = L10n.tr("Localizable", "graph.fixture.featured.summary", fallback: "Основатель промышленной группы")
      }
      public enum Relationship {
        /// Связь подтверждена редакционными источниками.
        public static let confirmed = L10n.tr("Localizable", "graph.fixture.relationship.confirmed", fallback: "Связь подтверждена редакционными источниками.")
        /// Источники расходятся в трактовке роли участников.
        public static let disputed = L10n.tr("Localizable", "graph.fixture.relationship.disputed", fallback: "Источники расходятся в трактовке роли участников.")
      }
    }
    public enum Node {
      /// Выбрать узел и показать его связи
      public static let hint = L10n.tr("Localizable", "graph.node.hint", fallback: "Выбрать узел и показать его связи")
      /// Выбрано
      public static let selected = L10n.tr("Localizable", "graph.node.selected", fallback: "Выбрано")
    }
    public enum Panel {
      /// Свернуть
      public static let collapse = L10n.tr("Localizable", "graph.panel.collapse", fallback: "Свернуть")
      /// Развернуть
      public static let expand = L10n.tr("Localizable", "graph.panel.expand", fallback: "Развернуть")
    }
    public enum People {
      /// Открыть список людей
      public static let `open` = L10n.tr("Localizable", "graph.people.open", fallback: "Открыть список людей")
    }
    public enum Relationship {
      /// Подтверждённая связь
      public static let confirmed = L10n.tr("Localizable", "graph.relationship.confirmed", fallback: "Подтверждённая связь")
      /// Связь оспаривается
      public static let disputed = L10n.tr("Localizable", "graph.relationship.disputed", fallback: "Связь оспаривается")
      /// Открыть доказательства и источники
      public static let evidence = L10n.tr("Localizable", "graph.relationship.evidence", fallback: "Открыть доказательства и источники")
      /// Открыть связь: %@
      public static func `open`(_ p1: Any) -> String {
        return L10n.tr("Localizable", "graph.relationship.open", String(describing: p1), fallback: "Открыть связь: %@")
      }
      /// Выбрать этого человека и центрировать граф
      public static let selectPerson = L10n.tr("Localizable", "graph.relationship.select_person", fallback: "Выбрать этого человека и центрировать граф")
      public enum Contexts {
        /// Совместный контекст
        public static let title = L10n.tr("Localizable", "graph.relationship.contexts.title", fallback: "Совместный контекст")
      }
      public enum Detail {
        /// Карточка связи
        public static let title = L10n.tr("Localizable", "graph.relationship.detail.title", fallback: "Карточка связи")
      }
      public enum Evidence {
        /// Утверждений: %d · источников: %d
        public static func summary(_ p1: Int, _ p2: Int) -> String {
          return L10n.tr("Localizable", "graph.relationship.evidence.summary", p1, p2, fallback: "Утверждений: %d · источников: %d")
        }
      }
      public enum Kind {
        /// Роль в совете
        public static let boardRole = L10n.tr("Localizable", "graph.relationship.kind.board_role", fallback: "Роль в совете")
        /// Совместное основание
        public static let cofounded = L10n.tr("Localizable", "graph.relationship.kind.cofounded", fallback: "Совместное основание")
        /// Сделка
        public static let deal = L10n.tr("Localizable", "graph.relationship.kind.deal", fallback: "Сделка")
        /// Образование
        public static let education = L10n.tr("Localizable", "graph.relationship.kind.education", fallback: "Образование")
        /// Работа
        public static let employment = L10n.tr("Localizable", "graph.relationship.kind.employment", fallback: "Работа")
        /// Руководящая роль
        public static let executiveRole = L10n.tr("Localizable", "graph.relationship.kind.executive_role", fallback: "Руководящая роль")
        /// Семейная связь
        public static let family = L10n.tr("Localizable", "graph.relationship.kind.family", fallback: "Семейная связь")
        /// Основание компании
        public static let founded = L10n.tr("Localizable", "graph.relationship.kind.founded", fallback: "Основание компании")
        /// Инвестиция
        public static let investment = L10n.tr("Localizable", "graph.relationship.kind.investment", fallback: "Инвестиция")
        /// Юридический спор
        public static let legalDispute = L10n.tr("Localizable", "graph.relationship.kind.legal_dispute", fallback: "Юридический спор")
        /// Владение
        public static let ownership = L10n.tr("Localizable", "graph.relationship.kind.ownership", fallback: "Владение")
        /// Филантропия
        public static let philanthropy = L10n.tr("Localizable", "graph.relationship.kind.philanthropy", fallback: "Филантропия")
        /// Совместный подтверждённый контекст
        public static let sharedContext = L10n.tr("Localizable", "graph.relationship.kind.shared_context", fallback: "Совместный подтверждённый контекст")
      }
      public enum Sources {
        /// Источники
        public static let title = L10n.tr("Localizable", "graph.relationship.sources.title", fallback: "Источники")
      }
    }
    public enum Relationships {
      /// У выбранного узла нет раскрытых связей
      public static let empty = L10n.tr("Localizable", "graph.relationships.empty", fallback: "У выбранного узла нет раскрытых связей")
    }
    public enum Reset {
      /// Вернуть камеру к человеку дня
      public static let camera = L10n.tr("Localizable", "graph.reset.camera", fallback: "Вернуть камеру к человеку дня")
    }
    public enum Sheet {
      /// Поиск людей
      public static let search = L10n.tr("Localizable", "graph.sheet.search", fallback: "Поиск людей")
      /// Люди
      public static let title = L10n.tr("Localizable", "graph.sheet.title", fallback: "Люди")
    }
    public enum Spike {
      /// Технический граф: 40 узлов и 80 связей
      public static let caption = L10n.tr("Localizable", "graph.spike.caption", fallback: "Технический граф: 40 узлов и 80 связей")
    }
    public enum Zoom {
      /// Приблизить граф
      public static let `in` = L10n.tr("Localizable", "graph.zoom.in", fallback: "Приблизить граф")
      /// Отдалить граф
      public static let out = L10n.tr("Localizable", "graph.zoom.out", fallback: "Отдалить граф")
    }
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg..., fallback value: String) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: value, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
