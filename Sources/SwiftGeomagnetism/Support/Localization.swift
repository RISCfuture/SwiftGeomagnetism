internal import Foundation

#if canImport(Darwin)
  /// A user-facing message, looked up in this package's resource bundle.
  typealias LocalizedMessage = String.LocalizationValue

  extension String {
    init(moduleLocalized message: LocalizedMessage) {
      self.init(localized: message, bundle: .module)
    }
  }
#else
  /**
   A user-facing message on platforms whose Foundation lacks `String.LocalizationValue`. It accepts
   the same `\(value, format:)` interpolations, so call sites are identical on every platform.
   */
  struct LocalizedMessage: ExpressibleByStringInterpolation {
    fileprivate let text: String

    init(stringLiteral value: String) {
      text = value
    }

    init(stringInterpolation: StringInterpolation) {
      text = stringInterpolation.text
    }

    struct StringInterpolation: StringInterpolationProtocol {
      fileprivate var text = ""

      init(literalCapacity: Int, interpolationCount _: Int) {
        text.reserveCapacity(literalCapacity)
      }

      mutating func appendLiteral(_ literal: String) {
        text += literal
      }

      mutating func appendInterpolation(_ value: some CustomStringConvertible) {
        text += value.description
      }

      mutating func appendInterpolation<Style: FormatStyle>(
        _ value: Style.FormatInput,
        format: Style
      ) where Style.FormatOutput == String {
        text += format.format(value)
      }
    }
  }

  extension String {
    init(moduleLocalized message: LocalizedMessage) {
      self = message.text
    }
  }
#endif
