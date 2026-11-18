import Foundation
@testable import SwiftGeomagnetism
import Testing

@Suite
struct `Decimal year conversion` {
  private static let cases: [(timestamp: String, decimalYear: Double)] = [
    ("2025-01-01T00:00:00Z", 2025),
    ("2025-07-02T12:00:00Z", 2025.5),
    ("2028-07-02T00:00:00Z", 2028 + 183.0 / 366),
    ("2028-12-31T18:00:00Z", 2028 + 365.75 / 366),
    ("2026-03-01T06:00:00+06:00", 2026 + 59.0 / 365)
  ]

  @Test(arguments: cases)
  func `converts an instant to a decimal year in UTC`(_ timestamp: String, _ decimalYear: Double)
    throws
  {
    let date = try Date(timestamp, strategy: .iso8601)
    #expect(abs(date.decimalYear - decimalYear) < 1e-12)
  }
}
