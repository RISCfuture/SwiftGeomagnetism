/// Constants of the WGS 84 ellipsoid, in kilometers to match the coefficient file's reference radius.
enum WGS84 {
  static let semiMajorAxis = 6378.137
  static let flattening = 1 / 298.257223563
  static let eccentricitySquared = flattening * (2 - flattening)
}

/// The radius of the sphere on which the World Magnetic Model's Gauss coefficients are defined, in
/// kilometers.
enum GeomagneticReferenceSphere {
  static let radius = 6371.2
}

/// Conversions between degrees and radians.
enum AngleConversion {
  static let radiansPerDegree = Double.pi / 180
  static let degreesPerRadian = 180 / Double.pi
}

/// Conversions between meters, as accepted by the public API, and kilometers, as used by the model.
enum LengthConversion {
  static let metersPerKilometer = 1000.0
}
