import Foundation
import SwiftGeomagnetism
import Testing

/// A quantity that appears as a column in NOAA's published test-value files.
enum TestQuantity: Sendable, CaseIterable {
  case decimalYear, heightKilometers, latitude, longitude
  case north, east, down, horizontal, total, inclination, declination, gridVariation
  case northRate, eastRate, downRate, horizontalRate, totalRate, inclinationRate, declinationRate

  /// The column labels NOAA uses for this quantity across its test-value files, lowercased and
  /// without the parenthesized unit.
  var labels: Set<String> {
    switch self {
      case .decimalYear: ["date", "decimal year"]
      case .heightKilometers: ["height above wgs84 ellipsoid", "altitude"]
      case .latitude: ["geodetic latitude"]
      case .longitude: ["geodetic longitude"]
      case .north: ["x"]
      case .east: ["y"]
      case .down: ["z"]
      case .horizontal: ["h"]
      case .total: ["f"]
      case .inclination: ["inclination"]
      case .declination: ["declination"]
      case .gridVariation: ["grid variation"]
      case .northRate: ["xdot", "dx/dt"]
      case .eastRate: ["ydot", "dy/dt"]
      case .downRate: ["zdot", "dz/dt"]
      case .horizontalRate: ["hdot", "dh/dt"]
      case .totalRate: ["fdot", "df/dt"]
      case .inclinationRate: ["idot", "di/dt"]
      case .declinationRate: ["ddot", "dd/dt"]
    }
  }

  /// Whether the quantity is an input to the model rather than a result.
  var isInput: Bool { [.decimalYear, .heightKilometers, .latitude, .longitude].contains(self) }

  /// Whether the quantity is an intensity in nanoteslas or its rate in nanoteslas per year.
  var isInNanoteslas: Bool {
    [
      .north, .east, .down, .horizontal, .total, .northRate, .eastRate, .downRate, .horizontalRate,
      .totalRate
    ]
    .contains(self)
  }

  /// Whether the quantity is an angle in degrees, compared modulo 360°.
  var isAngle: Bool { [.inclination, .declination, .gridVariation].contains(self) }

  init?(label: String) {
    let name = label.split(separator: "(").first?.trimmingCharacters(in: .whitespaces).lowercased()
    guard let name, let quantity = Self.allCases.first(where: { $0.labels.contains(name) }) else {
      return nil
    }
    self = quantity
  }

  /// The magnitude of the difference between two values of this quantity.
  func error(of actual: Double, from expected: Double) -> Double {
    let difference = actual - expected
    return abs(isAngle ? remainder(difference, 360) : difference)
  }

  /// This quantity's value in a computed field.
  func value(in field: MagneticField) -> Double? {
    switch self {
      case .decimalYear, .heightKilometers, .latitude, .longitude: nil
      case .north: field.northIntensity
      case .east: field.eastIntensity
      case .down: field.downwardIntensity
      case .horizontal: field.horizontalIntensity
      case .total: field.totalIntensity
      case .inclination: field.inclination
      case .declination: field.declination
      case .gridVariation: field.gridVariation
      case .northRate: field.secularVariation.northIntensity
      case .eastRate: field.secularVariation.eastIntensity
      case .downRate: field.secularVariation.downwardIntensity
      case .horizontalRate: field.secularVariation.horizontalIntensity
      case .totalRate: field.secularVariation.totalIntensity
      case .inclinationRate: field.secularVariation.inclination
      case .declinationRate: field.secularVariation.declination
    }
  }
}

/// A published value together with the precision it was printed to.
struct PublishedValue: Sendable {
  let value: Double

  /// Half a unit in the last printed decimal place: the most that rounding can have moved it.
  let roundingTolerance: Double

  /// `nil` where NOAA prints `NaN`, meaning the quantity is undefined at that point.
  var definedValue: Double? { value.isNaN ? nil : value }

  init?(_ token: Substring) {
    guard let value = Double(token) else { return nil }
    let decimalPlaces = token.split(separator: ".").dropFirst().first?.count ?? 0
    self.init(value: value, roundingTolerance: 0.5 * pow(10, -Double(decimalPlaces)))
  }

  private init(value: Double, roundingTolerance: Double) {
    self.value = value
    self.roundingTolerance = roundingTolerance
  }

  /// The same value and tolerance converted to another unit.
  func scaled(by factor: Double) -> Self {
    Self(value: value * factor, roundingTolerance: roundingTolerance * factor)
  }
}

/// One row of a NOAA test-value file.
struct NOAATestValue: Sendable, CustomTestStringConvertible {
  let source: String
  let values: [TestQuantity: PublishedValue]

  var decimalYear: Double { values[.decimalYear]!.value }
  var latitude: Double { values[.latitude]!.value }
  var longitude: Double { values[.longitude]!.value }
  var heightMeters: Double { values[.heightKilometers]!.value * 1000 }

  var testDescription: String {
    "\(source) \(decimalYear) \(latitude)° \(longitude)° \(heightMeters / 1000) km"
  }
}

/**
 Reads NOAA's test-value files as published. Their column order and labels differ between files,
 so columns are identified by the `# Field N: Label (unit)` comments at the top of each file.
 */
enum NOAATestValues {
  static func load(_ resource: String) throws -> [NOAATestValue] {
    guard let url = Bundle.module.url(forResource: resource, withExtension: "txt") else {
      throw TestResourceError.missing(resource)
    }
    let lines = try String(contentsOf: url, encoding: .utf8).split(whereSeparator: \.isNewline)
    let columns = try lines.filter { $0.hasPrefix("#") }.map {
      try quantity(inHeader: $0, of: resource)
    }

    return try lines.filter { !$0.hasPrefix("#") && !$0.allSatisfy(\.isWhitespace) }.map { line in
      let tokens = line.split(whereSeparator: \.isWhitespace)
      guard tokens.count == columns.count else {
        throw TestResourceError.malformed(resource, String(line))
      }
      let values = try tokens.map { token in
        guard let value = PublishedValue(token) else {
          throw TestResourceError.malformed(resource, String(line))
        }
        return value
      }
      return NOAATestValue(
        source: resource,
        values: Dictionary(uniqueKeysWithValues: zip(columns, values))
      )
    }
  }

  private static func quantity(inHeader line: Substring, of resource: String) throws -> TestQuantity
  {
    guard let label = line.split(separator: ":", maxSplits: 1).last,
      let quantity = TestQuantity(label: String(label))
    else { throw TestResourceError.malformed(resource, String(line)) }
    return quantity
  }
}

enum TestResourceError: Error {
  case missing(String)
  case malformed(String, String)
}
