# Getting Started

Calculate the magnetic field anywhere on or above Earth.

## Overview

A ``MagneticModel`` turns a position and a time into a ``MagneticField``. The bundled
``MagneticModel/wmm2025`` model covers 2025.0 through 2029.

### Calculating the Field

Pass a geodetic latitude and longitude in degrees. Height is in meters above the WGS 84
ellipsoid, not above mean sea level, and defaults to 0. The date defaults to now.

```swift
import SwiftGeomagnetism

let model = MagneticModel.wmm2025
let field = try model.field(
    latitude: 37.62,
    longitude: -122.38,
    heightAboveEllipsoid: 0,
    date: .now
)
```

If you already have a decimal year, such as 2027.5, call
``MagneticModel/field(latitude:longitude:heightAboveEllipsoid:decimalYear:)`` instead.

### Reading the Result

``MagneticField`` gives the field in the geodetic north–east–down frame, in nanoteslas, along
with the angles derived from it:

```swift
field.declination          // magnetic variation, degrees east of true north
field.inclination          // dip, degrees below horizontal
field.northIntensity       // X
field.eastIntensity        // Y
field.downwardIntensity    // Z
field.horizontalIntensity  // H
field.totalIntensity       // F
```

Poleward of 55° latitude, ``MagneticField/gridVariation`` gives the angle from grid north to
magnetic north for polar navigation. At lower latitudes it is `nil`.

### Tracking Change Over Time

``MagneticField/secularVariation`` holds the annual rate of change of every quantity:

```swift
field.secularVariation.declination  // degrees per year
```

### Using Measurements

Foundation `Measurement` versions of the arguments and results are available too. Intensities use
``UnitMagneticFluxDensity``:

```swift
let field = try model.field(
    latitude: Measurement(value: 37.62, unit: .degrees),
    longitude: Measurement(value: -122.38, unit: .degrees),
    heightAboveEllipsoid: Measurement(value: 10_000, unit: .feet)
)
field.declinationAngle                                    // Measurement<UnitAngle>
field.totalFluxDensity.converted(to: .microteslas)        // ≈ 47.3 µT
```

On Apple platforms, ``MagneticModel/field(at:)`` takes a `CLLocation`. It uses the location's
ellipsoidal altitude and its timestamp.

### Handling Errors

A model is only defined within its domain, so
``MagneticModel/field(latitude:longitude:heightAboveEllipsoid:date:)-(Double,_,_,_)`` throws a
``MagneticFieldError`` when:

- the latitude is outside −90° to 90°, or the longitude isn't finite;
- the height is outside ``MagneticModel/validHeights`` (−1 km to 850 km);
- the date is outside the model's ``MagneticModel/validityPeriod``.

After 2029, update to the next World Magnetic Model release. You can load it as a custom model,
as <doc:CustomModels> describes.
