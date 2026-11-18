# ``SwiftGeomagnetism/MagneticModel``

## Topics

### Bundled Models

- ``wmm2025``

### Loading Custom Models

- ``init(contentsOf:)``
- ``init(parsing:)``

### Calculating the Field

- ``field(latitude:longitude:heightAboveEllipsoid:date:)-(Double,_,_,_)``
- ``field(latitude:longitude:heightAboveEllipsoid:decimalYear:)``
- ``field(latitude:longitude:heightAboveEllipsoid:date:)-(Measurement<UnitAngle>,_,_,_)``
- ``field(at:)``

### Describing the Model

- ``name``
- ``epoch``
- ``releaseDate``
- ``maximumDegree``
- ``validityPeriod``
- ``validHeights``
