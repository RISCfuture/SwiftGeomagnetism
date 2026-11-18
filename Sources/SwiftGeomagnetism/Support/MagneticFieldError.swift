public import Foundation

/// Errors thrown when a magnetic field is requested outside a model's domain.
public enum MagneticFieldError: Error, Equatable, Sendable, LocalizedError {

  /// The latitude is not a finite value in [−90°, 90°].
  case invalidLatitude(_ latitude: Double)

  /// The longitude is not finite.
  case invalidLongitude(_ longitude: Double)

  /// The height above the WGS 84 ellipsoid, in meters, is outside ``MagneticModel/validHeights``.
  case heightOutsideValidRange(_ height: Double)

  /// The decimal year is outside the model's ``MagneticModel/validityPeriod``.
  case dateOutsideValidityPeriod(decimalYear: Double, validityPeriod: Range<Double>)

  public var errorDescription: String? {
    String(moduleLocalized: "Couldn’t calculate the magnetic field.")
  }

  public var failureReason: String? {
    switch self {
      case .invalidLatitude(let latitude):
        String(
          moduleLocalized: "The latitude \(latitude, format: .number) must be between −90° and 90°."
        )
      case .invalidLongitude(let longitude):
        String(
          moduleLocalized: "The longitude \(longitude, format: .number) is not a finite number."
        )
      case .heightOutsideValidRange(let height):
        String(
          moduleLocalized:
            "The height \(height, format: .number) m is outside the model’s valid range of −1 km to 850 km."
        )
      case let .dateOutsideValidityPeriod(decimalYear, validityPeriod):
        String(
          moduleLocalized:
            "The date (\(decimalYear, format: .number.grouping(.never).precision(.fractionLength(3)))) is outside the model’s validity period of \(validityPeriod.lowerBound, format: .number.grouping(.never).precision(.fractionLength(1))) to \(validityPeriod.upperBound, format: .number.grouping(.never).precision(.fractionLength(1)))."
        )
    }
  }

  public var recoverySuggestion: String? {
    switch self {
      case .dateOutsideValidityPeriod:
        String(
          moduleLocalized: "Update to a coefficient file whose validity period covers this date."
        )
      default: nil
    }
  }
}
