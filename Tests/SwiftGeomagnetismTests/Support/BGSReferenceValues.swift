import Foundation
import Testing

/// One point computed by the British Geological Survey's World Magnetic Model web service.
struct BGSReferenceValue: Sendable, CustomTestStringConvertible {
  let date: Date
  let dateString: String
  let latitude: Double
  let longitude: Double
  let heightMeters: Double
  let values: [TestQuantity: PublishedValue]

  var testDescription: String {
    "\(dateString) \(latitude)° \(longitude)° \(heightMeters / 1000) km"
  }
}

/**
 Reads `BGS_WMM2025_reference_values.csv`, written by `Scripts/generate-bgs-reference-values.sh`.
 Rates of angles arrive in arcminutes per year and are converted to degrees per year. The service
 evaluates a calendar date at noon UTC: its result for 2029-12-31 equals its result for decimal year
 2029.99863, not 2029.99726.
 */
enum BGSReferenceValues {
  private static let arcminutesPerDegree = 60.0
  private static let metersPerKilometer = 1000.0

  private static let resultColumns: [String: (quantity: TestQuantity, scale: Double)] = [
    "declination": (.declination, 1),
    "inclination": (.inclination, 1),
    "north_nT": (.north, 1),
    "east_nT": (.east, 1),
    "vertical_nT": (.down, 1),
    "horizontal_nT": (.horizontal, 1),
    "total_nT": (.total, 1),
    "declination_rate_arcmin": (.declinationRate, 1 / arcminutesPerDegree),
    "inclination_rate_arcmin": (.inclinationRate, 1 / arcminutesPerDegree),
    "north_rate_nT": (.northRate, 1),
    "east_rate_nT": (.eastRate, 1),
    "vertical_rate_nT": (.downRate, 1),
    "horizontal_rate_nT": (.horizontalRate, 1),
    "total_rate_nT": (.totalRate, 1)
  ]

  static func load() throws -> [BGSReferenceValue] {
    let resource = "BGS_WMM2025_reference_values"
    guard let url = Bundle.module.url(forResource: resource, withExtension: "csv") else {
      throw TestResourceError.missing(resource)
    }
    let rows = try String(contentsOf: url, encoding: .utf8)
      .split(whereSeparator: \.isNewline)
      .filter { !$0.hasPrefix("#") }
      .map { $0.split(separator: ",").map { $0.trimmingCharacters(in: ["\""])[...] } }
    guard let header = rows.first else { throw TestResourceError.malformed(resource, "") }

    return try rows.dropFirst().map { fields in
      let row = Dictionary(uniqueKeysWithValues: zip(header.map(String.init), fields))
      return try referenceValue(from: row, resource: resource)
    }
  }

  private static func referenceValue(
    from row: [String: Substring],
    resource: String
  ) throws -> BGSReferenceValue {
    guard let dateString = row["date"],
      let latitude = row["latitude"].flatMap({ Double($0) }),
      let longitude = row["longitude"].flatMap({ Double($0) }),
      let altitude = row["altitude_km"].flatMap({ Double($0) })
    else { throw TestResourceError.malformed(resource, row.description) }

    var values: [TestQuantity: PublishedValue] = [:]
    for (column, (quantity, scale)) in resultColumns {
      guard let value = row[column].flatMap({ PublishedValue($0) }) else {
        throw TestResourceError.malformed(resource, row.description)
      }
      values[quantity] = value.scaled(by: scale)
    }

    return BGSReferenceValue(
      date: try Date("\(dateString)T12:00:00Z", strategy: .iso8601),
      dateString: String(dateString),
      latitude: latitude,
      longitude: longitude,
      heightMeters: altitude * metersPerKilometer,
      values: values
    )
  }
}
