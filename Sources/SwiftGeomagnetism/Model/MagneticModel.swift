public import Foundation

/**
 A spherical-harmonic model of Earth's main magnetic field, such as the World Magnetic Model.

 Use the bundled ``wmm2025`` model, or load any coefficient (COF) file in NOAA's WMM format with
 ``init(contentsOf:)`` or ``init(parsing:)``. A model is immutable and `Sendable`, so one instance
 can serve concurrent callers.

 ```swift
 let field = try MagneticModel.wmm2025.field(latitude: 37.62, longitude: -122.38)
 print(field.declination)  // degrees east of true north
 ```
 */
public struct MagneticModel: Sendable {

  /**
   The range of heights above the WGS 84 ellipsoid, in meters, over which the World Magnetic Model
   is valid: 1 km below to 850 km above the ellipsoid.
   */
  public static let validHeights: ClosedRange<Double> = -1_000...850_000

  /// World Magnetic Model 2025 (degree 12), valid from 2025.0 through 2029.
  public static let wmm2025 = bundled(resource: "WMM2025", in: .module)

  private static let validityDuration = 5.0
  private static let validLatitudes = -90.0...90.0

  /// The model's name as given in its coefficient file, such as `WMM-2025`.
  public let name: String

  /// The decimal year at which the model's main-field coefficients apply, such as 2025.0.
  public let epoch: Double

  /// The release date given in the coefficient file, at midnight UTC.
  public let releaseDate: Date

  private let synthesis: FieldSynthesis

  /// The highest spherical-harmonic degree in the model: 12 for the WMM, 133 for the WMMHR.
  public var maximumDegree: UInt { UInt(synthesis.coefficients.maximumDegree) }

  /// The decimal years for which the model is valid: five years from its ``epoch``.
  public var validityPeriod: Range<Double> { epoch..<(epoch + Self.validityDuration) }

  /**
   Loads a model from a coefficient (COF) file in NOAA's WMM format.

   - Parameter url: The location of the file.
   - Throws: Any error reading the file, or a ``COFParseError`` if it is malformed.
   */
  public init(contentsOf url: URL) throws {
    guard let text = String(bytes: try Data(contentsOf: url), encoding: .utf8) else {
      throw COFParseError.notUTF8Text
    }
    try self.init(parsing: text)
  }

  /**
   Parses a model from the text of a coefficient (COF) file in NOAA's WMM format.

   The text is a header line (epoch, model name, and release date as `MM/DD/YYYY`), then one
   `n m g h ġ ḣ` line for every degree n ≥ 1 and order 0 ≤ m ≤ n, then a line of 9s. Any maximum
   degree is accepted.

   - Parameter text: The contents of the file.
   - Throws: ``COFParseError`` if the text is malformed.
   */
  public init(parsing text: String) throws(COFParseError) {
    let contents = try COFParser.parse(text)
    name = contents.name
    epoch = contents.epoch
    releaseDate = contents.releaseDate
    synthesis = FieldSynthesis(
      coefficients: contents.coefficients,
      recurrence: LegendreRecurrence(maximumDegree: contents.coefficients.maximumDegree)
    )
  }

  /**
   Loads a coefficient file that ships as a resource of this package.

   - Parameters:
     - resource: The file's name, without its `COF` extension.
     - bundle: The bundle containing the file.
   */
  package static func bundled(resource: String, in bundle: Bundle) -> Self {
    guard let url = bundle.url(forResource: resource, withExtension: "COF") else {
      fatalError("The \(resource).COF resource is missing from \(bundle.bundlePath)")
    }
    do {
      return try Self(contentsOf: url)
    } catch {
      fatalError("The bundled \(resource).COF resource is unreadable: \(error)")
    }
  }

  /**
   Calculates the magnetic field at a point and instant.

   - Parameters:
     - latitude: Geodetic latitude on the WGS 84 ellipsoid, in degrees, from −90 to 90.
     - longitude: Longitude, in degrees east. Any finite value is accepted.
     - heightAboveEllipsoid: Height above the WGS 84 ellipsoid, in meters, within
       ``validHeights``. This is not height above mean sea level, which differs by up to ±100 m.
     - date: The instant, which must fall within ``validityPeriod``.
   - Returns: The predicted field and its secular variation.
   - Throws: ``MagneticFieldError`` if any argument is outside the model's domain.
   */
  public func field(
    latitude: Double,
    longitude: Double,
    heightAboveEllipsoid: Double = 0,
    date: Date = .now
  ) throws(MagneticFieldError) -> MagneticField {
    try field(
      latitude: latitude,
      longitude: longitude,
      heightAboveEllipsoid: heightAboveEllipsoid,
      decimalYear: date.decimalYear
    )
  }

  /**
   Calculates the magnetic field at a point and decimal year.

   - Parameters:
     - latitude: Geodetic latitude on the WGS 84 ellipsoid, in degrees, from −90 to 90.
     - longitude: Longitude, in degrees east. Any finite value is accepted.
     - heightAboveEllipsoid: Height above the WGS 84 ellipsoid, in meters, within
       ``validHeights``.
     - decimalYear: The time as a decimal year, such as 2027.5, within ``validityPeriod``.
   - Returns: The predicted field and its secular variation.
   - Throws: ``MagneticFieldError`` if any argument is outside the model's domain.
   */
  public func field(
    latitude: Double,
    longitude: Double,
    heightAboveEllipsoid: Double = 0,
    decimalYear: Double
  ) throws(MagneticFieldError) -> MagneticField {
    try validate(
      latitude: latitude,
      longitude: longitude,
      heightAboveEllipsoid: heightAboveEllipsoid,
      decimalYear: decimalYear
    )

    let φ = latitude * AngleConversion.radiansPerDegree  // geodetic latitude (radians)
    let point = SphericalCoordinate(
      geodeticLatitude: φ,
      longitude: longitude * AngleConversion.radiansPerDegree,
      height: heightAboveEllipsoid / LengthConversion.metersPerKilometer
    )
    let synthesized = synthesis.evaluate(at: point, yearsSinceEpoch: decimalYear - epoch)
    let ψ = point.φʹ - φ  // geocentric minus geodetic latitude: the frame rotation angle (radians)

    return MagneticField(
      field: synthesized.field.rotatedToGeodetic(by: ψ),
      rates: synthesized.secularVariation.rotatedToGeodetic(by: ψ),
      latitude: latitude,
      longitude: longitude
    )
  }

  private func validate(
    latitude: Double,
    longitude: Double,
    heightAboveEllipsoid: Double,
    decimalYear: Double
  ) throws(MagneticFieldError) {
    guard Self.validLatitudes.contains(latitude) else { throw .invalidLatitude(latitude) }
    guard longitude.isFinite else { throw .invalidLongitude(longitude) }
    guard Self.validHeights.contains(heightAboveEllipsoid) else {
      throw .heightOutsideValidRange(heightAboveEllipsoid)
    }
    guard validityPeriod.contains(decimalYear) else {
      throw .dateOutsideValidityPeriod(decimalYear: decimalYear, validityPeriod: validityPeriod)
    }
  }
}
