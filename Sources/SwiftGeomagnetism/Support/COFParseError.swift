public import Foundation

/// Errors thrown when a coefficient (COF) file is malformed.
public enum COFParseError: Error, Equatable, Sendable, LocalizedError {

  /// The first line is not of the form `epoch model-name MM/DD/YYYY`.
  case malformedHeader(_ line: String)

  /// A coefficient line is not of the form `n m g h ġ ḣ`.
  case malformedCoefficientLine(lineNumber: UInt, line: String)

  /// A coefficient line names a degree below 1 or an order above its degree.
  case invalidDegreeOrOrder(lineNumber: UInt, degree: Int, order: Int)

  /// The same degree and order appear on more than one line.
  case duplicateCoefficient(lineNumber: UInt, degree: Int, order: Int)

  /// A degree and order below the file's maximum degree have no line.
  case missingCoefficient(degree: Int, order: Int)

  /// The file ends before the line of 9s that terminates the coefficients.
  case missingTerminator

  /// The file's contents are not valid UTF-8 text.
  case notUTF8Text

  public var errorDescription: String? {
    String(moduleLocalized: "Couldn’t read the magnetic model coefficient file.")
  }

  public var failureReason: String? {
    switch self {
      case .malformedHeader(let line):
        String(moduleLocalized: "The header “\(line)” is not of the form “epoch name MM/DD/YYYY”.")
      case let .malformedCoefficientLine(lineNumber, line):
        String(
          moduleLocalized:
            "Line \(lineNumber, format: .number.grouping(.never)) (“\(line)”) is not of the form “n m g h ġ ḣ”."
        )
      case let .invalidDegreeOrOrder(lineNumber, degree, order):
        String(
          moduleLocalized:
            "Line \(lineNumber, format: .number.grouping(.never)) has degree \(degree, format: .number.grouping(.never)) and order \(order, format: .number.grouping(.never)); the degree must be at least 1 and the order between 0 and the degree."
        )
      case let .duplicateCoefficient(lineNumber, degree, order):
        String(
          moduleLocalized:
            "Line \(lineNumber, format: .number.grouping(.never)) repeats degree \(degree, format: .number.grouping(.never)), order \(order, format: .number.grouping(.never))."
        )
      case let .missingCoefficient(degree, order):
        String(
          moduleLocalized:
            "No line gives degree \(degree, format: .number.grouping(.never)), order \(order, format: .number.grouping(.never))."
        )
      case .missingTerminator:
        String(
          moduleLocalized: "The file ends without the line of 9s that terminates the coefficients."
        )
      case .notUTF8Text:
        String(moduleLocalized: "The file is not UTF-8 text.")
    }
  }
}
