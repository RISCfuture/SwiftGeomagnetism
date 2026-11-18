# Custom Models

Load other releases of the World Magnetic Model, or any model in its coefficient format.

## Overview

NOAA publishes each World Magnetic Model as a coefficient (COF) file. Load one from disk with
``MagneticModel/init(contentsOf:)``, or from text with ``MagneticModel/init(parsing:)``:

```swift
let model = try MagneticModel(contentsOf: Bundle.main.url(forResource: "WMM", withExtension: "COF")!)
print(model.name)            // "WMM-2025"
print(model.validityPeriod)  // 2025.0..<2030.0
```

### The Coefficient Format

A COF file has a header line with the epoch, the model name, and the release date. Then comes one
line per degree n and order m, giving the Schmidt semi-normalized Gauss coefficients gₙᵐ and hₙᵐ
in nanoteslas, followed by their secular variation in nanoteslas per year. A line of 9s ends the
file:

```text
    2025.0            WMM-2025     11/13/2024
  1  0  -29351.8       0.0       12.0        0.0
  1  1   -1410.8    4545.4        9.7      -21.5
  …
999999999999999999999999999999999999999999999999
```

Any maximum degree is accepted, provided every degree and order up to it appears exactly once.
Parsing is strict: a malformed file throws a ``COFParseError`` that names the offending line.

### High Resolution

The `SwiftGeomagnetismHiRes` library adds `MagneticModel.wmmHiRes2025`, the degree-133 World
Magnetic Model High Resolution. That model adds Earth's crustal field to the WMM's core field.
It's a separate library because its coefficient file is about 530 KB. Apps that link only
`SwiftGeomagnetism` don't bundle it.
