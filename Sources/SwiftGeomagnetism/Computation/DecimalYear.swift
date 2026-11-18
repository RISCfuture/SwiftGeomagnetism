internal import Foundation

extension Date {
  private static let utcGregorian: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .gmt
    return calendar
  }()

  /// The instant as a decimal year in UTC, such as 2025.5 for midday on July 2, 2025. The fraction
  /// is the elapsed share of that calendar year, so leap years and the time of day both count.
  var decimalYear: Double {
    let calendar = Self.utcGregorian,
      year = calendar.component(.year, from: self)
    let startOfYear = Self.start(ofYear: year, in: calendar),
      startOfNextYear = Self.start(ofYear: year + 1, in: calendar)
    return Double(year) + timeIntervalSince(startOfYear)
      / startOfNextYear.timeIntervalSince(startOfYear)
  }

  private static func start(ofYear year: Int, in calendar: Calendar) -> Self {
    guard let start = calendar.date(from: DateComponents(year: year)) else {
      preconditionFailure("The Gregorian calendar has no start for year \(year)")
    }
    return start
  }
}
