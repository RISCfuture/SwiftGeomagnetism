internal import Foundation

/**
 The geomagnetic field at a point and instant, as predicted by a ``MagneticModel``.

 Components follow the geodetic north–east–down convention used by the World Magnetic Model:
 ``northIntensity`` (X) points to geographic north along the local meridian, ``eastIntensity`` (Y)
 points east, and ``downwardIntensity`` (Z) points toward the ellipsoid along the local vertical.
 Intensities are in nanoteslas and angles in degrees. ``secularVariation`` gives the annual rate
 of change of each quantity.
 */
public struct MagneticField: Sendable, Hashable, Codable {
  private static let polarRegionLatitude = 55.0
  private static let degreesPerTurn = 360.0

  /// The northward component X, in nanoteslas.
  public let northIntensity: Double

  /// The eastward component Y, in nanoteslas.
  public let eastIntensity: Double

  /// The downward component Z, in nanoteslas. Negative where the field points upward, as in the
  /// southern magnetic hemisphere.
  public let downwardIntensity: Double

  /**
   The grid variation (grivation), in degrees: the angle from grid north to magnetic north, east
   positive, in the polar stereographic grid NOAA defines poleward of 55° latitude. `nil` between
   55°S and 55°N, where the World Magnetic Model doesn't define it.
   */
  public let gridVariation: Double?

  /// The annual rate of change of each component of the field.
  public let secularVariation: SecularVariation

  /// The horizontal intensity H, in nanoteslas.
  public var horizontalIntensity: Double { hypot(northIntensity, eastIntensity) }

  /// The total intensity F, in nanoteslas.
  public var totalIntensity: Double { hypot(horizontalIntensity, downwardIntensity) }

  /**
   The declination D (magnetic variation), in degrees: the angle from true north to the horizontal
   component of the field, east positive, in (−180°, 180°].
   */
  public var declination: Double { Self.declination(north: northIntensity, east: eastIntensity) }

  /// The inclination I (dip), in degrees: the angle of the field below the horizontal plane, in
  /// [−90°, 90°].
  public var inclination: Double {
    atan2(downwardIntensity, horizontalIntensity) * AngleConversion.degreesPerRadian
  }

  /**
   Combines geodetic field components with the position they were computed for.

   - Parameters:
     - field: The main field, in nanoteslas.
     - rates: The secular variation of `field`, in nanoteslas per year.
     - latitude: Geodetic latitude, in degrees.
     - longitude: Longitude, in degrees.
   */
  init(field: FieldVector, rates: FieldVector, latitude: Double, longitude: Double) {
    northIntensity = field.north
    eastIntensity = field.east
    downwardIntensity = field.down
    secularVariation = SecularVariation(field: field, rates: rates)
    gridVariation = Self.gridVariation(
      declination: Self.declination(north: field.north, east: field.east),
      latitude: latitude,
      longitude: longitude
    )
  }

  private static func declination(north: Double, east: Double) -> Double {
    atan2(east, north) * AngleConversion.degreesPerRadian
  }

  private static func normalized(_ angle: Double) -> Double {
    let normalized = remainder(angle, degreesPerTurn)
    return normalized == -degreesPerTurn / 2 ? degreesPerTurn / 2 : normalized
  }

  private static func gridVariation(
    declination: Double,
    latitude: Double,
    longitude: Double
  ) -> Double? {
    if latitude >= polarRegionLatitude { return normalized(declination - longitude) }
    if latitude <= -polarRegionLatitude { return normalized(declination + longitude) }
    return nil
  }
}
