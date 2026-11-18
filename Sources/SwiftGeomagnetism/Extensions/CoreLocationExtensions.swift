#if canImport(CoreLocation)
  public import CoreLocation

  extension MagneticModel {
    /**
     Calculates the magnetic field at a location's coordinate, ellipsoidal altitude, and timestamp.

     - Parameter location: The location. Its `ellipsoidalAltitude`, not its mean-sea-level
       `altitude`, is used as the height.
     - Returns: The predicted field and its secular variation.
     - Throws: ``MagneticFieldError`` if the location or its timestamp is outside the model's
       domain.
     */
    public func field(at location: CLLocation) throws(MagneticFieldError) -> MagneticField {
      try field(
        latitude: location.coordinate.latitude,
        longitude: location.coordinate.longitude,
        heightAboveEllipsoid: location.ellipsoidalAltitude,
        date: location.timestamp
      )
    }
  }
#endif
