internal import Foundation

/// A point expressed in geocentric spherical coordinates, the frame in which the spherical-harmonic
/// expansion is evaluated.
struct SphericalCoordinate {
  let r: Double  // geocentric radius: distance from Earth's center to the point (km)
  let φʹ: Double  // geocentric latitude: angle from the equatorial plane to the radius (radians)
  let λ: Double  // longitude: angle east of the prime meridian (radians)

  /**
   Converts a geodetic position on the WGS 84 ellipsoid to geocentric spherical coordinates, exactly.

   - Parameters:
     - φ: Geodetic latitude, in radians.
     - λ: Longitude, in radians.
     - h: Height above the WGS 84 ellipsoid, in kilometers.
   */
  init(geodeticLatitude φ: Double, longitude λ: Double, height h: Double) {
    let sinφ = sin(φ), cosφ = cos(φ)  // sine and cosine of the geodetic latitude
    let primeVerticalRadius =
      WGS84.semiMajorAxis / (1 - WGS84.eccentricitySquared * sinφ * sinφ).squareRoot()
    let equatorialDistance = (primeVerticalRadius + h) * cosφ
    let polarDistance = (primeVerticalRadius * (1 - WGS84.eccentricitySquared) + h) * sinφ

    r = (equatorialDistance * equatorialDistance + polarDistance * polarDistance).squareRoot()
    φʹ = asin(polarDistance / r)
    self.λ = λ
  }
}
